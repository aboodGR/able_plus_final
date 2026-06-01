import 'dart:async';
import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/screens/Messages/chat_screen.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  static const Duration _queryTimeout = Duration(seconds: 10);
  static const int _maxConversations = 50;

  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _conversations = [];
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNow();
    });
  }

  Future<T> _safe<T>(
    String label,
    Future<T> Function() action,
    T fallback,
  ) async {
    try {
      return await Future.any<T>([
        action(),
        Future<T>.delayed(_queryTimeout, () => fallback),
      ]);
    } catch (e) {
      debugPrint('⚠️ $label failed: $e');
      return fallback;
    }
  }

  String _uiText(
    AppLocalizations l10n, {
    required String en,
    required String ar,
  }) {
    return l10n.localeName == 'ar' ? ar : en;
  }

  String _normalizeType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'clients':
        return 'client';
      case 'tutors':
        return 'tutor';
      case 'businesses':
        return 'business';
      case 'charities':
        return 'charity';
      default:
        return value.trim().toLowerCase();
    }
  }

  bool _sameType(String a, String b) {
    return _normalizeType(a) == _normalizeType(b);
  }

  List<String> _uniqueIds(Iterable<String> ids) {
    return ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id.toLowerCase() != 'null')
        .toSet()
        .toList();
  }

  Future<dynamic> _getViewer() async {
    try {
      return await Future.any<dynamic>([
        ref.read(viewerProvider.future),
        Future<dynamic>.delayed(_queryTimeout, () => null),
      ]);
    } catch (e) {
      debugPrint('⚠️ viewerProvider failed: $e');
      return null;
    }
  }

  Future<void> _loadNow({bool refresh = false}) async {
    final token = ++_loadToken;

    if (mounted) {
      setState(() {
        if (refresh) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }
      });
    }

    try {
      final items = await _loadConversationsSafe();

      if (!mounted || token != _loadToken) return;

      setState(() {
        _conversations = items;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('❌ messages load crashed: $e');

      if (!mounted || token != _loadToken) return;

      setState(() {
        _conversations = [];
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<List<dynamic>> _fetchConversationRows(
    List<String> myIds,
    String myType,
  ) async {
    final supabase = Supabase.instance.client;
    final ids = _uniqueIds(myIds);

    if (ids.isEmpty) return [];

    return _safe<List<dynamic>>(
      'fetch conversations',
      () async {
        final orParts = <String>[];

        for (final id in ids) {
          orParts.add('participant_a_id.eq.$id');
          orParts.add('participant_b_id.eq.$id');
        }

        final rows = await supabase
            .from('conversations')
            .select(
              'id, participant_a_id, participant_a_type, participant_b_id, participant_b_type, updated_at, deleted_by',
            )
            .or(orParts.join(','))
            .order('updated_at', ascending: false)
            .limit(_maxConversations);

        debugPrint('👤 Message viewer IDs: $ids type=$myType');
        debugPrint('📦 Fetched conversation rows: ${(rows as List).length}');

        return List<dynamic>.from(rows);
      },
      <dynamic>[],
    );
  }

  Future<List<dynamic>> _fetchBlockRows(
    List<String> myIds,
    String myType,
  ) async {
    final supabase = Supabase.instance.client;
    final ids = _uniqueIds(myIds);

    if (ids.isEmpty) return [];

    return _safe<List<dynamic>>(
      'fetch user blocks',
      () async {
        final orParts = <String>[];

        for (final id in ids) {
          orParts.add('blocker_id.eq.$id');
          orParts.add('blocked_id.eq.$id');
        }

        final rows = await supabase
            .from('user_blocks')
            .select('blocker_id, blocker_type, blocked_id, blocked_type')
            .or(orParts.join(','));

        debugPrint('🚫 Fetched block rows: ${(rows as List).length}');

        return List<dynamic>.from(rows);
      },
      <dynamic>[],
    );
  }

  Future<Map<String, dynamic>?> _fetchOtherUser(String otherId) async {
    if (otherId.isEmpty) return null;

    return _safe<Map<String, dynamic>?>(
      'fetch other user',
      () async {
        final supabase = Supabase.instance.client;

        var row = await supabase
            .from('app_users')
            .select(
              'id, display_name, username, profile_pic_url, account_type, auth_user_id',
            )
            .eq('id', otherId)
            .maybeSingle();

        row ??= await supabase
            .from('app_users')
            .select(
              'id, display_name, username, profile_pic_url, account_type, auth_user_id',
            )
            .eq('auth_user_id', otherId)
            .maybeSingle();

        if (row == null) return null;

        return Map<String, dynamic>.from(row as Map);
      },
      null,
    );
  }

  Future<Map<String, dynamic>?> _fetchLastMessage(String conversationId) async {
    if (conversationId.isEmpty) return null;

    return _safe<Map<String, dynamic>?>(
      'fetch last message',
      () async {
        final row = await Supabase.instance.client
            .from('messages')
            .select(
              'message_text, shared_post_id, created_at, sender_id, sender_type, is_seen',
            )
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (row == null) return null;

        return Map<String, dynamic>.from(row as Map);
      },
      null,
    );
  }

  Future<int> _fetchUnreadCount(
    String conversationId,
    List<String> myIds,
  ) async {
    if (conversationId.isEmpty) return 0;

    final ids = _uniqueIds(myIds);
    if (ids.isEmpty) return 0;

    return _safe<int>(
      'fetch unread count',
      () async {
        final rows = await Supabase.instance.client
            .from('messages')
            .select('id, sender_id')
            .eq('conversation_id', conversationId)
            .eq('is_seen', false);

        int count = 0;

        for (final raw in rows as List) {
          if (raw is! Map) continue;

          final senderId = raw['sender_id']?.toString() ?? '';
          if (!ids.contains(senderId)) {
            count++;
          }
        }

        return count;
      },
      0,
    );
  }

  Future<List<Map<String, dynamic>>> _loadConversationsSafe() async {
    final supabase = Supabase.instance.client;
    final viewer = await _getViewer();

    if (viewer == null) {
      debugPrint('⚠️ viewer is null, messages list will be empty');
      return [];
    }

    final currentAuthUserId = supabase.auth.currentUser?.id?.toString() ?? '';
    final viewerId = viewer.id?.toString() ?? '';
    final viewerAuthId = viewer.authUserId?.toString() ?? '';
    final myType = _normalizeType(viewer.role?.toString() ?? '');

    final myIds = _uniqueIds([
      viewerId,
      viewerAuthId,
      currentAuthUserId,
    ]);

    if (myIds.isEmpty || myType.isEmpty) {
      debugPrint('⚠️ missing viewer id/type');
      return [];
    }

    final rows = await _fetchConversationRows(myIds, myType);
    final blocks = await _fetchBlockRows(myIds, myType);

    final blockedByMeSet = <String>{};
    final blockedByOtherSet = <String>{};

    for (final raw in blocks) {
      if (raw is! Map) continue;

      final b = Map<String, dynamic>.from(raw);

      final blockerId = b['blocker_id']?.toString() ?? '';
      final blockerType = b['blocker_type']?.toString() ?? '';
      final blockedId = b['blocked_id']?.toString() ?? '';
      final blockedType = b['blocked_type']?.toString() ?? '';

      if (myIds.contains(blockerId) && _sameType(blockerType, myType)) {
        blockedByMeSet.add('$blockedId:${_normalizeType(blockedType)}');
      } else if (myIds.contains(blockedId) && _sameType(blockedType, myType)) {
        blockedByOtherSet.add('$blockerId:${_normalizeType(blockerType)}');
      }
    }

    final visibleConversations = <Map<String, dynamic>>[];

    for (final raw in rows) {
      if (raw is! Map) continue;

      final conv = Map<String, dynamic>.from(raw);

      // المحادثة لا تختفي بسبب البلوك.
      // تختفي فقط إذا المستخدم نفسه عمل Delete Chat وانضاف ID تبعه إلى deleted_by.
      final deletedByRaw = conv['deleted_by'];
      if (deletedByRaw is List) {
        final deletedForMe = deletedByRaw.any((id) {
          final value = id?.toString() ?? '';
          return myIds.contains(value);
        });

        if (deletedForMe) {
          continue;
        }
      }

      visibleConversations.add(conv);
    }

    debugPrint(
      '👁️ Visible conversation rows after deleted_by filter: ${visibleConversations.length}',
    );

    final futures = visibleConversations.map((conv) async {
      final convId = conv['id']?.toString() ?? '';

      final aId = conv['participant_a_id']?.toString() ?? '';
      final aType = conv['participant_a_type']?.toString() ?? '';
      final bId = conv['participant_b_id']?.toString() ?? '';
      final bType = conv['participant_b_type']?.toString() ?? '';

      final bool iAmA =
          myIds.contains(aId) && (aType.isEmpty || _sameType(aType, myType));

      final otherId = iAmA ? bId : aId;
      final otherType = _normalizeType(iAmA ? bType : aType);

      final data = await Future.wait<dynamic>([
        _fetchOtherUser(otherId),
        _fetchLastMessage(convId),
        _fetchUnreadCount(convId, myIds),
      ]);

      final otherUser = data[0] as Map<String, dynamic>?;
      final lastMsg = data[1] as Map<String, dynamic>?;
      final unreadCount = data[2] as int? ?? 0;

      final messageText = lastMsg?['message_text']?.toString().trim() ?? '';
      final sharedPostId = lastMsg?['shared_post_id']?.toString().trim() ?? '';

      final lastMessage = messageText.isNotEmpty
          ? messageText
          : sharedPostId.isNotEmpty
              ? '__shared_post__'
              : '';

      final otherUserIdForDisplay =
          otherUser?['id']?.toString().trim().isNotEmpty == true
              ? otherUser!['id'].toString()
              : otherId;

      final key = '$otherId:$otherType';
      final normalizedOtherKey = '$otherUserIdForDisplay:$otherType';

      final blockedByMe = blockedByMeSet.contains(key) ||
          blockedByMeSet.contains(normalizedOtherKey);
      final blockedByOther = blockedByOtherSet.contains(key) ||
          blockedByOtherSet.contains(normalizedOtherKey);

      return <String, dynamic>{
        'conversation_id': convId,
        'other_id': otherUserIdForDisplay,
        'other_type': otherUser?['account_type']?.toString() ?? otherType,
        'other_name': otherUser?['display_name']?.toString() ??
            otherUser?['username']?.toString() ??
            '',
        'other_username': otherUser?['username']?.toString() ?? '',
        'other_image': otherUser?['profile_pic_url']?.toString(),
        'last_message': lastMessage,
        'last_message_at': lastMsg?['created_at']?.toString() ??
            conv['updated_at']?.toString() ??
            '',
        'unread_count': unreadCount,
        'is_blocked': blockedByMe || blockedByOther,
        'blocked_by_me': blockedByMe,
        'blocked_by_other': blockedByOther,
      };
    }).toList();

    final result = await _safe<List<Map<String, dynamic>>>(
      'build conversations',
      () async => Future.wait(futures),
      <Map<String, dynamic>>[],
    );

    result.sort((a, b) {
      final aDate = DateTime.tryParse(a['last_message_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['last_message_at']?.toString() ?? '');

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    debugPrint('✅ Messages loaded: ${result.length}');

    return result;
  }

  Future<void> _confirmDeleteConversation(String conversationId) async {
    if (conversationId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          _uiText(
            l10n,
            en: 'Delete chat?',
            ar: 'حذف المحادثة؟',
          ),
        ),
        content: Text(
          _uiText(
            l10n,
            en: 'This will hide this chat from your messages list only.',
            ar: 'سيتم إخفاء هذه المحادثة من قائمة رسائلك فقط.',
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
            child: Text(l10n.deleteChat),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteConversationForMe(conversationId);
    }
  }

  Future<void> deleteConversationForMe(String conversationId) async {
    if (conversationId.isEmpty) return;

    final oldItems = List<Map<String, dynamic>>.from(_conversations);

    setState(() {
      _conversations.removeWhere(
        (item) => item['conversation_id']?.toString() == conversationId,
      );
    });

    final ok = await _hideConversationForMe(conversationId);

    if (!mounted) return;

    if (!ok) {
      setState(() => _conversations = oldItems);

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
    }
  }

  Future<bool> _hideConversationForMe(String conversationId) async {
    final supabase = Supabase.instance.client;
    final viewer = await _getViewer();

    final authUserId = supabase.auth.currentUser?.id?.toString() ?? '';
    final viewerId = viewer == null ? '' : viewer.id?.toString() ?? '';
    final viewerAuthId =
        viewer == null ? '' : viewer.authUserId?.toString() ?? '';

    final idsToSave = _uniqueIds([
      authUserId,
      viewerId,
      viewerAuthId,
    ]);

    if (idsToSave.isEmpty || conversationId.isEmpty) return false;

    final data = await _safe<Map<String, dynamic>?>(
      'read deleted_by',
      () async {
        final row = await supabase
            .from('conversations')
            .select('deleted_by')
            .eq('id', conversationId)
            .maybeSingle();

        if (row == null) return null;

        return Map<String, dynamic>.from(row as Map);
      },
      null,
    );

    final deletedBy = <dynamic>[];
    final rawDeletedBy = data?['deleted_by'];

    if (rawDeletedBy is List) {
      deletedBy.addAll(rawDeletedBy);
    }

    for (final id in idsToSave) {
      if (!deletedBy.any((value) => value?.toString() == id)) {
        deletedBy.add(id);
      }
    }

    return _safe<bool>(
      'update deleted_by',
      () async {
        await supabase
            .from('conversations')
            .update({'deleted_by': deletedBy})
            .eq('id', conversationId);

        return true;
      },
      false,
    );
  }

  Future<void> _blockUserFromList(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final supabase = Supabase.instance.client;
    final viewer = await _getViewer();

    if (!mounted) return;

    if (viewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
      return;
    }

    final otherId = item['other_id']?.toString() ?? '';
    final otherType = _normalizeType(item['other_type']?.toString() ?? '');

    if (otherId.isEmpty || otherType.isEmpty) {
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
            en: 'You will still be able to view old messages, but sending new messages should be blocked in the chat screen.',
            ar: 'ستبقى قادرًا على رؤية الرسائل القديمة، لكن إرسال رسائل جديدة يجب أن يتوقف داخل صفحة المحادثة.',
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

    final ok = await _safe<bool>(
      'block user',
      () async {
        await supabase.from('user_blocks').upsert({
          'blocker_id': viewer.id?.toString() ?? '',
          'blocker_type': _normalizeType(viewer.role?.toString() ?? ''),
          'blocked_id': otherId,
          'blocked_type': otherType,
        });

        return true;
      },
      false,
    );

    if (!mounted) return;

    if (ok) {
      final conversationId = item['conversation_id']?.toString() ?? '';

      setState(() {
        for (final conv in _conversations) {
          if (conv['conversation_id']?.toString() == conversationId) {
            conv['is_blocked'] = true;
            conv['blocked_by_me'] = true;
            conv['unread_count'] = conv['unread_count'] ?? 0;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userBlocked)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
    }
  }

  Future<void> _unblockUserFromList(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final supabase = Supabase.instance.client;
    final viewer = await _getViewer();

    if (!mounted) return;

    if (viewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
      return;
    }

    final otherId = item['other_id']?.toString() ?? '';
    final otherType = _normalizeType(item['other_type']?.toString() ?? '');
    final myId = viewer.id?.toString() ?? '';

    if (otherId.isEmpty || otherType.isEmpty || myId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
      return;
    }

    final ok = await _safe<bool>(
      'unblock user',
      () async {
        await supabase
            .from('user_blocks')
            .delete()
            .eq('blocker_id', myId)
            .eq('blocked_id', otherId);

        return true;
      },
      false,
    );

    if (!mounted) return;

    if (ok) {
      final conversationId = item['conversation_id']?.toString() ?? '';
      final blockedByOther = item['blocked_by_other'] == true;

      setState(() {
        for (final conv in _conversations) {
          if (conv['conversation_id']?.toString() == conversationId) {
            conv['blocked_by_me'] = false;
            conv['is_blocked'] = blockedByOther;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _uiText(
              l10n,
              en: 'User unblocked.',
              ar: 'تم إلغاء حظر المستخدم.',
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
    }
  }

  String _formatTime(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return '';

    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.timeNow;
    if (diff.inMinutes < 60) return l10n.minutesShort(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursShort(diff.inHours);
    if (diff.inDays < 7) return l10n.daysShort(diff.inDays);

    return '${date.day}/${date.month}';
  }

  String _blockedSubtitle(
    AppLocalizations l10n, {
    required bool blockedByMe,
    required bool blockedByOther,
  }) {
    if (blockedByMe && blockedByOther) return l10n.youBothBlockedShort;
    if (blockedByMe) return l10n.youBlockedThisUser;
    if (blockedByOther) return l10n.thisUserBlockedYou;
    return l10n.messagesHidden;
  }

  Widget _emptyState(AppLocalizations l10n, Color mutedColor) {
    return RefreshIndicator(
      onRefresh: () => _loadNow(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
        children: [
          TtsWrapper(
            text: l10n.noMessagesYet,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AbleTheme.glassCard(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AbleTheme.glassBorder(context)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 64,
                        color: mutedColor.withOpacity(0.45),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noMessagesYet,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AbleTheme.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _uiText(
                          l10n,
                          en: 'Your conversations will appear here when you start chatting.',
                          ar: 'ستظهر محادثاتك هنا عندما تبدأ الدردشة.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedColor,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => _loadNow(refresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingState(AppLocalizations l10n, Color mutedColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            l10n.localeName == 'ar'
                ? 'جاري تحميل الرسائل...'
                : 'Loading messages...',
            style: TextStyle(color: mutedColor),
          ),
        ],
      ),
    );
  }

  void _showBlockedSnack(
    AppLocalizations l10n, {
    required bool blockedByMe,
    required bool blockedByOther,
  }) {
    final message = _blockedSubtitle(
      l10n,
      blockedByMe: blockedByMe,
      blockedByOther: blockedByOther,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);

    return AbleScaffold(
      title: l10n.messages,
      currentIndex: 3,
      showBackButton: true,
      body: Stack(
        children: [
          if (_isLoading)
            _loadingState(l10n, mutedColor)
          else if (_conversations.isEmpty)
            _emptyState(l10n, mutedColor)
          else
            RefreshIndicator(
              onRefresh: () => _loadNow(refresh: true),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _conversations[index];

                  final originalImage = item['other_image']?.toString();

                  final originalName =
                      (item['other_name']?.toString() ?? '').isNotEmpty
                          ? item['other_name'].toString()
                          : l10n.unknown;

                  final originalUsername =
                      item['other_username']?.toString() ?? '';

                  final otherId = item['other_id']?.toString() ?? '';
                  final otherType = item['other_type']?.toString() ?? '';

                  final rawLastMessageRaw =
                      item['last_message']?.toString() ?? '';

                  final rawLastMessage = rawLastMessageRaw == '__shared_post__'
                      ? l10n.sharedAPost
                      : rawLastMessageRaw;

                  final time =
                      _formatTime(l10n, item['last_message_at']?.toString());

                  final isBlocked = item['is_blocked'] == true;
                  final blockedByMe = item['blocked_by_me'] == true;
                  final blockedByOther = item['blocked_by_other'] == true;

                  final unreadCount = item['unread_count'] as int? ?? 0;

                  // مهم:
                  // البلوك لا يخفي الاسم والصورة ولا يمنع دخول المحادثة.
                  // فقط صفحة ChatScreen لازم تمنع الإرسال إذا كان هناك بلوك.
                  final displayName = originalName;
                  final displayImage = originalImage;
                  final displayUsername = originalUsername;

                  final blockedNote = isBlocked
                      ? _blockedSubtitle(
                          l10n,
                          blockedByMe: blockedByMe,
                          blockedByOther: blockedByOther,
                        )
                      : '';

                  final displayLastMessage = rawLastMessage.isNotEmpty
                      ? rawLastMessage
                      : blockedNote;

                  final spokenParts = <String>[displayName];

                  if (displayLastMessage.isNotEmpty) {
                    spokenParts.add(displayLastMessage);
                  }

                  if (blockedNote.isNotEmpty) {
                    spokenParts.add(blockedNote);
                  }

                  if (time.isNotEmpty) spokenParts.add(time);

                  if (unreadCount > 0) {
                    spokenParts.add(
                      l10n.localeName == 'ar'
                          ? '$unreadCount رسائل غير مقروءة'
                          : '$unreadCount unread',
                    );
                  }

                  return TtsWrapper(
                    text: spokenParts.join('. '),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AbleTheme.glassCard(context),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: unreadCount > 0
                                  ? AbleTheme.primary(context).withOpacity(0.35)
                                  : isBlocked
                                      ? Colors.redAccent.withOpacity(0.22)
                                      : AbleTheme.glassBorder(context),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: displayImage != null &&
                                          displayImage.isNotEmpty
                                      ? NetworkImage(displayImage)
                                      : null,
                                  child:
                                      displayImage == null || displayImage.isEmpty
                                          ? Text(
                                              displayName.isNotEmpty
                                                  ? displayName
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                  : '?',
                                            )
                                          : null,
                                ),
                                if (unreadCount > 0)
                                  PositionedDirectional(
                                    end: 0,
                                    top: 0,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: AbleTheme.primary(context),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w900
                                          : FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (isBlocked) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.block_rounded,
                                    size: 16,
                                    color: Colors.redAccent.withOpacity(0.85),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayUsername.isEmpty
                                      ? displayLastMessage
                                      : '@$displayUsername • $displayLastMessage',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: unreadCount > 0
                                        ? textColor
                                        : mutedColor,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (isBlocked && blockedNote.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    blockedNote,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (time.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: mutedColor),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'delete_for_me',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_sweep_outlined,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.deleteChat,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                if (blockedByMe)
                                  PopupMenuItem(
                                    value: 'unblock_user',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.lock_open_rounded,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _uiText(
                                            l10n,
                                            en: 'Unblock user',
                                            ar: 'إلغاء الحظر',
                                          ),
                                          style: const TextStyle(
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  PopupMenuItem(
                                    value: 'block_user',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.block_rounded,
                                          color: Colors.redAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.blockUserMenu,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              onSelected: (value) async {
                                if (value == 'delete_for_me') {
                                  await _confirmDeleteConversation(
                                    item['conversation_id'].toString(),
                                  );
                                } else if (value == 'block_user') {
                                  await _blockUserFromList(item);
                                } else if (value == 'unblock_user') {
                                  await _unblockUserFromList(item);
                                }
                              },
                            ),
                            onTap: () {
                              // حتى لو في بلوك، نسمح بدخول المحادثة لرؤية الرسائل القديمة.
                              // منع الإرسال يجب أن يكون داخل ChatScreen.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversationId:
                                        item['conversation_id'].toString(),
                                    otherName: originalName,
                                    otherImage: originalImage,
                                    otherId: otherId,
                                    otherType: otherType,
                                  ),
                                ),
                              ).then((_) => _loadNow(refresh: true));
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_isRefreshing)
            PositionedDirectional(
              top: 10,
              end: 16,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AbleTheme.primary(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
