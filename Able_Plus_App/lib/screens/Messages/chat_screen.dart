import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/Screens/Post/PostDetailsScreen.dart';
import 'package:ableplusproject/services/tts_service.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
    required this.otherId,
    required this.otherType,
    this.otherImage,
  });

  final String conversationId;
  final String otherName;
  final String otherId;
  final String otherType;
  final String? otherImage;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AppViewer? _viewer;
  late Future<void> _initialFuture;

  bool _isBlocked = false;
  bool _blockedByMe = false;
  bool _blockedByOther = false;
  DateTime? _blockStartedAt;

  final List<Map<String, dynamic>> _optimisticMessages = [];
  final Set<String> _deletedMessageIds = {};
  final Map<String, Map<String, dynamic>> _editedMessages = {};
  final Map<String, Future<Map<String, dynamic>?>> _sharedPostCache = {};

  Future<Map<String, dynamic>?> _getSharedPostFuture(String postId) {
    return _sharedPostCache.putIfAbsent(
      postId,
      () => _loadSharedPost(postId),
    );
  }

  @override
  void initState() {
    super.initState();
    _initialFuture = _loadViewer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _uiText(
    AppLocalizations l10n, {
    required String en,
    required String ar,
  }) {
    return l10n.localeName == 'ar' ? ar : en;
  }

  String _normalizeType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'clients':
        return 'client';
      case 'tutors':
        return 'tutor';
      case 'businesses':
        return 'business';
      case 'charities':
        return 'charity';
      default:
        return type.trim().toLowerCase();
    }
  }

  bool _sameType(String a, String b) {
    return _normalizeType(a) == _normalizeType(b);
  }

  Future<void> _loadViewer() async {
    _viewer = await ref.read(viewerProvider.future);
    await _loadBlockStatus();
    await _markSeen();
  }

  Future<void> _markSeen() async {
    final viewer = _viewer;
    if (viewer == null) return;

    try {
      await Supabase.instance.client.rpc(
        'mark_conversation_seen',
        params: {
          'p_conversation_id': widget.conversationId,
          'p_my_id': viewer.id,
          'p_my_type': viewer.role,
        },
      );
    } catch (_) {}
  }

  Future<void> _loadBlockStatus() async {
    final viewer = _viewer;
    if (viewer == null) return;
    if (widget.otherId.isEmpty || widget.otherType.isEmpty) return;

    final supabase = Supabase.instance.client;
    final myType = _normalizeType(viewer.role);
    final otherType = _normalizeType(widget.otherType);

    final blocks = await supabase
        .from('user_blocks')
        .select(
          'blocker_id, blocker_type, blocked_id, blocked_type, created_at',
        )
        .or(
          'and(blocker_id.eq.${viewer.id},blocker_type.eq.$myType,'
          'blocked_id.eq.${widget.otherId},blocked_type.eq.$otherType),'
          'and(blocker_id.eq.${widget.otherId},blocker_type.eq.$otherType,'
          'blocked_id.eq.${viewer.id},blocked_type.eq.$myType)',
        );

    Map<String, dynamic>? blockByMe;
    Map<String, dynamic>? blockByOther;

    for (final b in blocks) {
      final blockerId = b['blocker_id']?.toString() ?? '';
      final blockerType = _normalizeType(b['blocker_type']?.toString() ?? '');

      if (blockerId == viewer.id && _sameType(blockerType, myType)) {
        blockByMe = Map<String, dynamic>.from(b as Map);
      } else {
        blockByOther = Map<String, dynamic>.from(b as Map);
      }
    }

    final myBlockDate =
        DateTime.tryParse(blockByMe?['created_at']?.toString() ?? '');
    final otherBlockDate =
        DateTime.tryParse(blockByOther?['created_at']?.toString() ?? '');

    DateTime? startedAt;

    if (myBlockDate != null && otherBlockDate != null) {
      startedAt = myBlockDate.isBefore(otherBlockDate)
          ? myBlockDate.toLocal()
          : otherBlockDate.toLocal();
    } else if (myBlockDate != null) {
      startedAt = myBlockDate.toLocal();
    } else if (otherBlockDate != null) {
      startedAt = otherBlockDate.toLocal();
    }

    if (!mounted) return;

    setState(() {
      _blockedByMe = blockByMe != null;
      _blockedByOther = blockByOther != null;
      _isBlocked = blockByMe != null || blockByOther != null;
      _blockStartedAt = startedAt;
    });
  }

  Future<void> _blockUser() async {
    final l10n = AppLocalizations.of(context)!;
    final viewer = _viewer;

    if (viewer == null) return;

    if (widget.otherId.isEmpty || widget.otherType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotBlockMissingInfo)),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.blockUserQuestion),
        content: Text(
          _uiText(
            l10n,
            en:
                'You can still open this chat and view old messages. New messages will be blocked until you unblock this user.',
            ar:
                'ستبقى قادرًا على فتح المحادثة ورؤية الرسائل القديمة. سيتم منع الرسائل الجديدة حتى تلغي الحظر.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.block),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('user_blocks').upsert({
        'blocker_id': viewer.id,
        'blocker_type': _normalizeType(viewer.role),
        'blocked_id': widget.otherId,
        'blocked_type': _normalizeType(widget.otherType),
      });

      await _loadBlockStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userBlocked)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.blockFailed(e.toString()))),
      );
    }
  }

  Future<void> _unblockUser() async {
    final l10n = AppLocalizations.of(context)!;
    final viewer = _viewer;

    if (viewer == null) return;

    try {
      await Supabase.instance.client
          .from('user_blocks')
          .delete()
          .eq('blocker_id', viewer.id)
          .eq('blocker_type', _normalizeType(viewer.role))
          .eq('blocked_id', widget.otherId)
          .eq('blocked_type', _normalizeType(widget.otherType));

      await _loadBlockStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userUnblocked)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.unblockFailed(e.toString()))),
      );
    }
  }

  void _openOtherProfile() {
    final l10n = AppLocalizations.of(context)!;

    if (widget.otherId.isEmpty || widget.otherType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileInfoMissing)),
      );
      return;
    }

    context.push('/profile/${widget.otherType}/${widget.otherId}');
  }

  String _formatMessageTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  bool _isEdited(Map<String, dynamic> message) {
    final createdAt = message['created_at']?.toString();
    final updatedAt = message['updated_at']?.toString();

    if (createdAt == null || updatedAt == null) return false;
    if (createdAt.isEmpty || updatedAt.isEmpty) return false;

    final created = DateTime.tryParse(createdAt);
    final updated = DateTime.tryParse(updatedAt);

    if (created == null || updated == null) return false;

    return updated.difference(created).inSeconds.abs() > 2;
  }

  Stream<List<Map<String, dynamic>>> _messagesStream() {
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  bool _shouldHideMessageDuringBlock(Map<String, dynamic> msg) {
    if (!_isBlocked) return false;

    final blockStartedAt = _blockStartedAt;
    if (blockStartedAt == null) return false;

    if (_isMyMessage(msg)) return false;

    final createdAt = DateTime.tryParse(msg['created_at']?.toString() ?? '');
    if (createdAt == null) return false;

    return createdAt.toLocal().isAfter(blockStartedAt) ||
        createdAt.toLocal().isAtSameMomentAs(blockStartedAt);
  }

  List<Map<String, dynamic>> _mergeMessages(
    List<Map<String, dynamic>> serverMessages,
  ) {
    final viewer = _viewer;

    final filtered = serverMessages.where((msg) {
      final id = msg['id']?.toString();

      if (id == null || _deletedMessageIds.contains(id)) return false;
      if (_shouldHideMessageDuringBlock(msg)) return false;

      if (viewer != null) {
        final deletedBy = msg['deleted_by'];

        if (deletedBy != null) {
          final list = List<String>.from(
            (deletedBy as List).map((e) => e.toString()),
          );

          if (list.contains(viewer.id)) return false;
        }
      }

      return true;
    }).map((msg) {
      final id = msg['id']?.toString();

      if (id != null && _editedMessages.containsKey(id)) {
        return {...msg, ..._editedMessages[id]!};
      }

      return msg;
    }).toList();

    final serverIds = filtered.map((m) => m['id'].toString()).toSet();

    final localOnly = _optimisticMessages.where((msg) {
      final id = msg['id']?.toString();

      return id != null &&
          !serverIds.contains(id) &&
          !_deletedMessageIds.contains(id) &&
          !_shouldHideMessageDuringBlock(msg);
    }).toList();

    final merged = [...filtered, ...localOnly];

    merged.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return merged;
  }

  Future<Map<String, dynamic>?> _loadSharedPost(String postId) async {
    try {
      final supabase = Supabase.instance.client;

      final post = await supabase
          .from('posts')
          .select(
            'content, image_url, client_id, tutor_id, business_id, charity_id',
          )
          .eq('id', postId)
          .maybeSingle();

      if (post == null) return null;

      String authorId = '';
      String authorRole = '';
      String authorName = '';
      String? authorImage;

      String? profileColumn;
      String? authorTable;
      String authorSelect = 'id, username';

      if (post['client_id'] != null) {
        authorId = post['client_id'].toString();
        authorRole = 'client';
        authorTable = 'clients';
        profileColumn = 'client_id';
      } else if (post['tutor_id'] != null) {
        authorId = post['tutor_id'].toString();
        authorRole = 'tutor';
        authorTable = 'tutors';
        profileColumn = 'tutor_id';
      } else if (post['business_id'] != null) {
        authorId = post['business_id'].toString();
        authorRole = 'business';
        authorTable = 'businesses';
        profileColumn = 'business_id';
      } else if (post['charity_id'] != null) {
        authorId = post['charity_id'].toString();
        authorRole = 'charity';
        authorTable = 'charities';
        profileColumn = 'charity_id';
        authorSelect = 'id, username, charity_name';
      }

      if (authorId.isNotEmpty && authorTable != null) {
        try {
          final author = await supabase
              .from(authorTable)
              .select(authorSelect)
              .eq('id', authorId)
              .maybeSingle();

          if (author != null) {
            if (authorRole == 'charity') {
              final charityName = author['charity_name']?.toString() ?? '';
              final username = author['username']?.toString() ?? '';

              authorName = charityName.isNotEmpty
                  ? charityName
                  : (username.isNotEmpty ? username : 'Charity');
            } else {
              authorName = author['username']?.toString() ?? '';
            }
          }
        } catch (e) {
          debugPrint('_loadSharedPost author error: $e');
        }
      }

      if (authorId.isNotEmpty && profileColumn != null) {
        try {
          final profile = await supabase
              .from('profiles')
              .select('profile_pic_url')
              .eq(profileColumn, authorId)
              .maybeSingle();

          authorImage = profile?['profile_pic_url']?.toString();
        } catch (e) {
          debugPrint('_loadSharedPost profile error: $e');
        }
      }

      String? imageUrl = post['image_url']?.toString();

      if (imageUrl == null || imageUrl.isEmpty) {
        try {
          final media = await supabase
              .from('media')
              .select('file_url')
              .eq('post_id', postId)
              .eq('media_type', 'post')
              .eq('file_type', 'image')
              .limit(1)
              .maybeSingle();

          imageUrl = media?['file_url']?.toString();
        } catch (e) {
          debugPrint('_loadSharedPost media image error: $e');
        }
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        try {
          final media = await supabase
              .from('media')
              .select('file_url')
              .eq('post_id', postId)
              .limit(1)
              .maybeSingle();

          imageUrl = media?['file_url']?.toString();
        } catch (e) {
          debugPrint('_loadSharedPost media fallback error: $e');
        }
      }

      return {
        'post_id': postId,
        'content': post['content']?.toString() ?? '',
        'image': imageUrl,
        'author_name': authorName,
        'author_image': authorImage,
        'author_id': authorId,
        'author_role': authorRole,
      };
    } catch (e) {
      debugPrint('_loadSharedPost error: $e');
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    final viewer = _viewer;

    if (text.isEmpty || viewer == null) return;

    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _uiText(
              l10n,
              en: 'You cannot send messages while this chat is blocked.',
              ar: 'لا يمكنك إرسال رسائل أثناء وجود حظر في هذه المحادثة.',
            ),
          ),
        ),
      );
      return;
    }

    _controller.clear();

    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';

    final tempMessage = <String, dynamic>{
      'id': tempId,
      'conversation_id': widget.conversationId,
      'sender_id': viewer.id,
      'sender_type': viewer.role,
      'message_text': text,
      'shared_post_id': null,
      'is_seen': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': null,
      '_is_temp': true,
    };

    setState(() => _optimisticMessages.add(tempMessage));

    await Future.delayed(const Duration(milliseconds: 50));
    _scrollToBottom();

    try {
      final inserted = await Supabase.instance.client
          .from('messages')
          .insert({
            'conversation_id': widget.conversationId,
            'sender_id': viewer.id,
            'sender_type': viewer.role,
            'message_text': text,
          })
          .select()
          .single();

      if (!mounted) return;

      setState(() {
        final index =
            _optimisticMessages.indexWhere((msg) => msg['id'] == tempId);

        if (index != -1) {
          _optimisticMessages[index] = Map<String, dynamic>.from(inserted);
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _optimisticMessages.removeWhere((msg) => msg['id'] == tempId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sendFailed(e.toString()))),
      );
    }
  }

  Future<void> _editMessage(Map<String, dynamic> message) async {
    final l10n = AppLocalizations.of(context)!;

    if (message['_is_temp'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.waitUntilSent)),
      );
      return;
    }

    final messageId = message['id']?.toString();
    if (messageId == null || messageId.isEmpty) return;

    final controller = TextEditingController(
      text: message['message_text']?.toString() ?? '',
    );

    final newText = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.editMessage),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(hintText: l10n.messageDialogHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newText == null || newText.isEmpty) return;

    final updatedAt = DateTime.now().toUtc().toIso8601String();

    setState(() {
      _editedMessages[messageId] = {
        'message_text': newText,
        'updated_at': updatedAt,
      };
    });

    try {
      await Supabase.instance.client
          .from('messages')
          .update({'message_text': newText, 'updated_at': updatedAt}).eq(
        'id',
        messageId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.messageUpdated)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _editedMessages.remove(messageId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editFailed(e.toString()))),
      );
    }
  }

  Future<void> _deleteMessageForEveryone(Map<String, dynamic> message) async {
    final l10n = AppLocalizations.of(context)!;
    final messageId = message['id']?.toString();

    if (messageId == null || messageId.isEmpty) return;

    if (message['_is_temp'] == true) {
      setState(() {
        _optimisticMessages.removeWhere(
          (msg) => msg['id'].toString() == messageId,
        );
      });

      return;
    }

    setState(() {
      _deletedMessageIds.add(messageId);
      _optimisticMessages.removeWhere(
        (msg) => msg['id'].toString() == messageId,
      );
    });

    try {
      await Supabase.instance.client
          .from('messages')
          .delete()
          .eq('id', messageId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.messageDeleted)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _deletedMessageIds.remove(messageId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
      );
    }
  }

  void _showDeleteOptions(Map<String, dynamic> message) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          AbleTheme.isDark(context) ? const Color(0xFF182437) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AbleTheme.textMuted(context).withOpacity(0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.redAccent,
              ),
              title: Text(
                l10n.deleteForEveryone,
                style: const TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteMessageForEveryone(message);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openMessageOptions(Map<String, dynamic> message) {
    final l10n = AppLocalizations.of(context)!;
    final isMine = _isMyMessage(message);
    final isTemp = message['_is_temp'] == true;
    final sharedPostId = message['shared_post_id']?.toString();
    final isSharedPost = sharedPostId != null && sharedPostId.isNotEmpty;

    if (!isMine) return;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          AbleTheme.isDark(context) ? const Color(0xFF182437) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AbleTheme.textMuted(context).withOpacity(0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 10),
            if (!isSharedPost && !isTemp)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.editMessage),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                l10n.deleteMessageMenu,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteOptions(message);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  void _speak(String text) {
    if (!ref.read(ttsEnabledProvider)) return;
    if (text.trim().isEmpty) return;

    final lang = ref.read(languageProvider).languageCode;

    TtsService.instance.speak(text, enabled: true, lang: lang);
  }

  Widget _ttsWrap(String text, Widget child) {
    if (kIsWeb || _isDesktop) {
      return MouseRegion(onEnter: (_) => _speak(text), child: child);
    }

    return GestureDetector(onLongPress: () => _speak(text), child: child);
  }

  bool _isMyMessage(Map<String, dynamic> message) {
    final viewer = _viewer;
    if (viewer == null) return false;

    final messageSenderId = message['sender_id']?.toString();
    final messageSenderType = _normalizeType(
      message['sender_type']?.toString() ?? '',
    );

    return messageSenderId == viewer.id &&
        messageSenderType == _normalizeType(viewer.role);
  }

  Widget _messageBubble(
    Map<String, dynamic> message, {
    required bool showSeen,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isMe = _isMyMessage(message);
    final text = message['message_text']?.toString();
    final sharedPostId = message['shared_post_id']?.toString();
    final hasSharedPost = sharedPostId != null && sharedPostId.isNotEmpty;

    final bubbleColor =
        isMe ? AbleTheme.primary(context) : AbleTheme.glassCard(context);
    final textColor = isMe ? Colors.white : AbleTheme.textPrimary(context);

    final time = _formatMessageTime(message['created_at']);
    final edited = _isEdited(message);
    final isTemp = message['_is_temp'] == true;

    final infoParts = <String>[
      if (time.isNotEmpty) time,
      if (edited) l10n.edited,
      if (isTemp) l10n.sendingStatus,
      if (!_isBlocked && !isTemp && showSeen) l10n.seenStatus,
    ];

    final isAr = l10n.localeName == 'ar';

    final speakerLabel = isMe ? (isAr ? 'أنت' : 'You') : widget.otherName;
    final bodyForSpeech = hasSharedPost ? l10n.sharedAPost : (text ?? '');

    final spokenText = [
      speakerLabel,
      bodyForSpeech,
      if (time.isNotEmpty) time,
    ].where((p) => p.trim().isNotEmpty).join('. ');

    final bubble = GestureDetector(
      onTap: () {
        if (!kIsWeb && !_isDesktop) _speak(spokenText);
        if (isMe) _openMessageOptions(message);
      },
      onLongPress: () => _openMessageOptions(message),
      child: Align(
        alignment: isMe
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: isTemp ? 0.72 : 1,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: hasSharedPost
                    ? const EdgeInsets.all(8)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: const Radius.circular(20),
                    topEnd: const Radius.circular(20),
                    bottomStart: Radius.circular(isMe ? 20 : 4),
                    bottomEnd: Radius.circular(isMe ? 4 : 20),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AbleTheme.glassBorder(context)),
                ),
                child: hasSharedPost
                    ? _SharedPostBubble(
                        postId: sharedPostId,
                        isMe: isMe,
                        loadSharedPost: _getSharedPostFuture,
                      )
                    : Text(
                        text ?? '',
                        style: TextStyle(color: textColor, height: 1.35),
                      ),
              ),
            ),
            if (infoParts.isNotEmpty)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: isMe ? 8 : 0,
                  start: isMe ? 0 : 8,
                  top: 1,
                  bottom: 4,
                ),
                child: Text(
                  infoParts.join(' · '),
                  style: TextStyle(
                    color: AbleTheme.textMuted(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (kIsWeb || _isDesktop) {
      return MouseRegion(onEnter: (_) => _speak(spokenText), child: bubble);
    }

    return bubble;
  }

  int _lastSeenMineIndex(List<Map<String, dynamic>> messages) {
    if (_isBlocked) return -1;

    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];

      if (msg['_is_temp'] == true) continue;
      if (_isMyMessage(msg) && msg['is_seen'] == true) return i;
    }

    return -1;
  }

  Widget _blockedNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String message = '';

    if (_blockedByMe && _blockedByOther) {
      message = l10n.youBothBlocked;
    } else if (_blockedByMe) {
      message = l10n.youBlockedAbleUser;
    } else if (_blockedByOther) {
      message = l10n.ableUserBlockedYou;
    }

    if (message.isEmpty) return const SizedBox.shrink();

    return _ttsWrap(
      message,
      Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AbleTheme.glassCard(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AbleTheme.glassBorder(context)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AbleTheme.textMuted(context),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _messageInput(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AbleTheme.glassCard(context),
        border: Border(top: BorderSide(color: AbleTheme.glassBorder(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isBlocked,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: _isBlocked
                    ? l10n.messageWillAppearAfterUnblock
                    : l10n.messageHintDefault,
                filled: true,
                fillColor: AbleTheme.panelFill(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isBlocked
                ? AbleTheme.textMuted(context).withOpacity(0.45)
                : AbleTheme.primary(context),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isBlocked ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);

    final displayName = widget.otherName;
    final displayImage = widget.otherImage;

    return FutureBuilder<void>(
      future: _initialFuture,
      builder: (context, snapshot) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AbleTheme.isDark(context)
                ? const Color(0x99101828)
                : Colors.white.withOpacity(0.65),
            elevation: 0,
            titleSpacing: 0,
            title: _ttsWrap(
              displayName,
              InkWell(
                onTap: _openOtherProfile,
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundImage:
                          displayImage != null && displayImage.isNotEmpty
                              ? NetworkImage(displayImage)
                              : null,
                      child: displayImage == null || displayImage.isEmpty
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName.substring(0, 1).toUpperCase()
                                  : '?',
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'block') _blockUser();
                  if (value == 'unblock') _unblockUser();
                },
                itemBuilder: (_) => [
                  if (!_blockedByMe)
                    PopupMenuItem(
                      value: 'block',
                      child: Text(AppLocalizations.of(context)!.blockUserMenu),
                    ),
                  if (_blockedByMe)
                    PopupMenuItem(
                      value: 'unblock',
                      child:
                          Text(AppLocalizations.of(context)!.unblockUserMenu),
                    ),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  AbleTheme.backgroundAsset(context),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(color: AbleTheme.screenOverlay(context)),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _blockedNotice(context),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _messagesStream(),
                        builder: (context, snapshot) {
                          final serverMessages = snapshot.data ?? [];
                          final messages = _mergeMessages(serverMessages);

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (snapshot.hasData) _markSeen();
                            _scrollToBottom();
                          });

                          if (!snapshot.hasData && messages.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (messages.isEmpty) {
                            return Center(
                              child: _ttsWrap(
                                AppLocalizations.of(context)!
                                    .startTheConversation,
                                Text(
                                  AppLocalizations.of(context)!
                                      .startTheConversation,
                                  style: TextStyle(color: mutedColor),
                                ),
                              ),
                            );
                          }

                          final lastSeenIndex = _lastSeenMineIndex(messages);

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) => _messageBubble(
                              messages[index],
                              showSeen: index == lastSeenIndex,
                            ),
                          );
                        },
                      ),
                    ),
                    _messageInput(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SharedPostBubble extends StatelessWidget {
  const _SharedPostBubble({
    required this.postId,
    required this.isMe,
    required this.loadSharedPost,
  });

  final String postId;
  final bool isMe;
  final Future<Map<String, dynamic>?> Function(String) loadSharedPost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);

    return FutureBuilder<Map<String, dynamic>?>(
      future: loadSharedPost(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isMe
                          ? Colors.white70
                          : AbleTheme.textMuted(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.loadingPost,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white70
                          : AbleTheme.textMuted(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link_off_rounded,
                  size: 16,
                  color: isMe
                      ? Colors.white60
                      : AbleTheme.textMuted(context),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.postUnavailable,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white60
                        : AbleTheme.textMuted(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final post = snapshot.data!;
        final content = post['content']?.toString() ?? '';
        final image = post['image']?.toString();
        final authorName = post['author_name']?.toString() ?? '';
        final authorImage = post['author_image']?.toString();

        final cardBg = isMe
            ? Colors.white.withOpacity(0.15)
            : (isDark ? const Color(0xFF1E2D42) : Colors.white);
        final cardBorder = isMe
            ? Colors.white.withOpacity(0.25)
            : AbleTheme.glassBorder(context);
        final textColor = isMe ? Colors.white : AbleTheme.textPrimary(context);
        final mutedColor =
            isMe ? Colors.white70 : AbleTheme.textMuted(context);

        final tapHint = l10n.localeName == 'ar'
            ? 'اضغط لفتح البوست'
            : 'Tap to open post';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailsScreen(postId: postId),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image != null && image.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: Image.network(
                          image,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (authorName.isNotEmpty)
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundImage: authorImage != null &&
                                          authorImage.isNotEmpty
                                      ? NetworkImage(authorImage)
                                      : null,
                                  child:
                                      authorImage == null || authorImage.isEmpty
                                          ? Text(
                                              authorName.isNotEmpty
                                                  ? authorName[0].toUpperCase()
                                                  : '?',
                                              style:
                                                  const TextStyle(fontSize: 8),
                                            )
                                          : null,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (authorName.isNotEmpty) const SizedBox(height: 5),
                          Text(
                            content.isNotEmpty ? content : l10n.sharedAPost,
                            maxLines: image != null ? 2 : 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: mutedColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tapHint,
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
