import 'dart:convert';
import 'dart:ui';
import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ableplusproject/Models/PostModel.dart';
import 'package:ableplusproject/widgets/PostVideoPlayer.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/notificationsProvider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/VipBadge.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post});

  final PostModel post;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late bool localIsLiked;
  late int localLikes;
  late int localComments;
  late String localContent;
  late List<String> localImages;
  String? localVideoUrl;
  bool localIsSaved = false;
  bool isSavingPost = false;

  bool isDeleted = false;

  @override
  void initState() {
    super.initState();
    localIsLiked = widget.post.isLiked;
    localLikes = widget.post.likes;
    localComments = widget.post.comments;
    localContent = widget.post.content;
    localImages = List<String>.from(widget.post.images ?? []);
    localVideoUrl = widget.post.videoUrl;
    _checkIfSaved();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post.id != widget.post.id) {
      _checkIfSaved();
    }

    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.likes != widget.post.likes ||
        oldWidget.post.comments != widget.post.comments ||
        oldWidget.post.content != widget.post.content ||
        oldWidget.post.images != widget.post.images ||
        oldWidget.post.videoUrl != widget.post.videoUrl) {
      localIsLiked = widget.post.isLiked;
      localLikes = widget.post.likes;
      localComments = widget.post.comments;
      localContent = widget.post.content;
      localImages = List<String>.from(widget.post.images ?? []);
      localVideoUrl = widget.post.videoUrl;
    }
  }

  /// Reads whether the current viewer has saved this post.
  /// Matches public.saved_posts columns:
  /// post_id + client_id/tutor_id/business_id/charity_id.
  Future<void> _checkIfSaved() async {
    try {
      final supabase = Supabase.instance.client;
      final viewer = await ref.read(viewerProvider.future);

      if (viewer == null) {
        if (mounted) setState(() => localIsSaved = false);
        return;
      }

      final userColumn = _savedUserColumn(viewer);
      final rows = await supabase
          .from('saved_posts')
          .select('id')
          .eq('post_id', widget.post.id)
          .eq(userColumn, viewer.id)
          .limit(1);

      if (!mounted) return;
      setState(() => localIsSaved = rows.isNotEmpty);
    } catch (e) {
      debugPrint('CHECK SAVE ERROR: $e');
      if (mounted) setState(() => localIsSaved = false);
    }
  }

  /// Saves/removes a post using the `saved_posts` SQL table.
  Future<void> _toggleSave(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (isSavingPost) return;

    final viewer = await ref.read(viewerProvider.future);
    if (viewer == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseLoginFirst)),
      );
      return;
    }

    final oldSaved = localIsSaved;
    final userColumn = _savedUserColumn(viewer);

    setState(() {
      isSavingPost = true;
      localIsSaved = !oldSaved;
    });

    try {
      final supabase = Supabase.instance.client;

      if (oldSaved) {
        await supabase
            .from('saved_posts')
            .delete()
            .eq('post_id', widget.post.id)
            .eq(userColumn, viewer.id);
      } else {
        // The SQL partial unique indexes prevent saving the same post twice.
        // Insert is used here because the unique indexes include WHERE clauses.
        await supabase.from('saved_posts').insert({
          'post_id': widget.post.id,
          userColumn: viewer.id,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(oldSaved
              ? l10n.removedFromSaved
              : l10n.postSavedSuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('TOGGLE SAVE ERROR: $e');
      if (!mounted) return;
      setState(() => localIsSaved = oldSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailedError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => isSavingPost = false);
    }
  }

  /// Only these columns exist in the SQL saved_posts table.
  String _savedUserColumn(AppViewer viewer) {
    switch (viewer.role) {
      case 'client':
        return 'client_id';
      case 'tutor':
        return 'tutor_id';
      case 'business':
        return 'business_id';
      case 'charity':
        return 'charity_id';
      default:
        throw UnsupportedError('Unsupported viewer role: ${viewer.role}');
    }
  }

  bool _isOwnPost(AppViewer? viewer) {
    if (viewer == null) return false;
    return viewer.role == widget.post.postType &&
        viewer.id == widget.post.authorId;
  }

  String _formatPostTime(AppLocalizations l10n, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return l10n.justNow;
    if (difference.inMinutes < 60) return l10n.minutesAgo(difference.inMinutes);
    if (difference.inHours < 24) return l10n.hoursAgo(difference.inHours);
    if (difference.inDays < 7) return l10n.daysAgo(difference.inDays);

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case 'client':
        return l10n.postRoleClient;
      case 'tutor':
        return l10n.postRoleTutor;
      case 'business':
        return l10n.postRoleBusiness;
      case 'charity':
        return l10n.postRoleCharity;
      default:
        return role;
    }
  }

  /// Prevents the generated share caption from appearing below video posts,
  /// while still allowing a real user-written caption to be displayed.
  bool _shouldShowPostContent({required bool hasPostVideo}) {
    final content = localContent.trim();
    if (content.isEmpty) return false;

    final normalized = content.toLowerCase();
    const fixedVideoShareCaptions = <String>{
      'shared a post.',
      'shared a post',
      'shared this post.',
      'shared this post',
      'تمت مشاركة منشور.',
      'تمت مشاركة منشور',
    };

    return !(hasPostVideo && fixedVideoShareCaptions.contains(normalized));
  }

  Widget _buildFollowButton({
    required String targetId,
    required String targetType,
    required Color primaryColor,
    required Color textColor,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final args = (targetId: targetId, targetType: targetType);
    final followState = ref.watch(followStateProvider(args));

    if (followState.isLoading) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final isFollowing = followState.isFollowing;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        ref.read(followStateProvider(args).notifier).toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : primaryColor,
          border: Border.all(
            color: isFollowing
                ? (isDark
                    ? Colors.white.withOpacity(0.30)
                    : primaryColor.withOpacity(0.50))
                : primaryColor,
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isFollowing ? l10n.following : l10n.follow,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isFollowing
                ? (isDark ? Colors.white : primaryColor)
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final oldLiked = localIsLiked;
    final oldLikes = localLikes;

    try {
      final supabase = Supabase.instance.client;
      final viewer = await ref.read(viewerProvider.future);

      if (viewer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseLoginFirst)),
        );
        return;
      }

      final deletedLikes = await supabase
          .from('post_likes')
          .delete()
          .eq('post_id', widget.post.id)
          .eq(viewer.userColumn, viewer.id)
          .select('id');

      if (deletedLikes.isEmpty) {
        await supabase.from('post_likes').insert({
          'post_id': widget.post.id,
          viewer.userColumn: viewer.id,
        });

        final receiverAuthId = await _lookupAuthorAuthId(
            widget.post.authorId, widget.post.postType);

        if (receiverAuthId != null && receiverAuthId != viewer.authUserId) {
          await supabase.from('notifications').insert({
            'type': 'like',
            'title': 'New like',
            'message': '${viewer.username} liked your post',
            'related_user_id': viewer.authUserId,
            'related_post_id': widget.post.id,
            'receiver_id': receiverAuthId,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        if (!mounted) return;
        setState(() {
          localIsLiked = true;
          localLikes = oldLikes + 1;
        });
      } else {
        if (!mounted) return;
        setState(() {
          localIsLiked = false;
          localLikes = oldLikes > 0 ? oldLikes - 1 : 0;
        });
      }

      ref.invalidate(postsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
    } catch (e) {
      debugPrint('LIKE ERROR: $e');

      if (!mounted) return;

      setState(() {
        localIsLiked = oldLiked;
        localLikes = oldLikes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.likeFailedError(e.toString()))),
      );
    }
  }

  Future<void> _openComments(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        postId: widget.post.id,
        postAuthorId: widget.post.authorId,
        postAuthorRole: widget.post.postType,
        onCommentAdded: () {
          if (!mounted) return;
          setState(() {
            localComments = localComments + 1;
          });
          ref.invalidate(postsProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationsProvider);
        },
        onCommentDeleted: () {
          if (!mounted) return;
          setState(() {
            localComments = localComments > 0 ? localComments - 1 : 0;
          });
          ref.invalidate(postsProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationsProvider);
        },
      ),
    );
  }

  Future<void> _openPostMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final viewer = await ref.read(viewerProvider.future);
    final ownPost = _isOwnPost(viewer);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetColor = isDark ? const Color(0xFF182437) : Colors.white;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ownPost
                  ? [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(l10n.editPost),
                        onTap: () {
                          Navigator.pop(context);
                          _openEditPostSheet(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        title: Text(
                          l10n.deletePost,
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeletePost(context);
                        },
                      ),
                    ]
                  : [
                      ListTile(
                        leading: const Icon(Icons.flag_outlined,
                            color: Colors.orange),
                        title: Text(
                          l10n.reportPost,
                          style: const TextStyle(color: Colors.orange),
                        ),
                        subtitle: Text(
                          l10n.reportPostSubtitle,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _openReportSheet(context);
                        },
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openReportSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    bool isSending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
            final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
            final sheetColor = isDark ? const Color(0xFF182437) : Colors.white;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            l10n.reportPost,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AbleTheme.textPrimary(sheetContext),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.reportPostBody,
                        style: TextStyle(
                          color: AbleTheme.textMuted(sheetContext),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: reasonController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: l10n.reportPostReasonHint,
                          filled: true,
                          fillColor: AbleTheme.panelFill(sheetContext),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSending
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSending
                                  ? null
                                  : () async {
                                      final reason =
                                          reasonController.text.trim();
                                      if (reason.isEmpty) {
                                        ScaffoldMessenger.of(sheetContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                l10n.pleaseWriteShortReason),
                                          ),
                                        );
                                        return;
                                      }
                                      setSheetState(() => isSending = true);
                                      final ok = await _submitReport(reason);
                                      if (!sheetContext.mounted) return;
                                      Navigator.pop(sheetContext);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(ok
                                              ? l10n.reportSentThanks
                                              : l10n.couldNotSendReportTryAgain),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              icon: isSending
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_outlined, size: 18),
                              label: Text(l10n.submit),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _submitReport(String reason) async {
    try {
      final supabase = Supabase.instance.client;
      final viewer = await ref.read(viewerProvider.future);
      if (viewer == null) return false;

      await supabase.from('post_reports').insert({
        'post_id': widget.post.id,
        'reported_by': viewer.id,
        'message': reason,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('REPORT ERROR: $e');
      return false;
    }
  }

  Future<void> _confirmDeletePost(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deletePostQuestion),
        content: Text(l10n.deletePostBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('posts').delete().eq('id', widget.post.id);

      if (!mounted) return;

      setState(() => isDeleted = true);

      ref.invalidate(postsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deletePostFailedError(e.toString()))),
      );
    }
  }

  Future<void> _openEditPostSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final contentController = TextEditingController(text: localContent);
    XFile? pickedImage;
    XFile? pickedVideo;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
            final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
            final sheetColor = isDark ? const Color(0xFF182437) : Colors.white;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editPost,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AbleTheme.textPrimary(sheetContext),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: contentController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: l10n.editYourPost,
                            filled: true,
                            fillColor: AbleTheme.panelFill(sheetContext),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (pickedImage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AbleTheme.panelFill(sheetContext),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AbleTheme.glassBorder(sheetContext),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.image_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.newImageLabel(pickedImage!.name),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AbleTheme.textMuted(sheetContext),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () =>
                                      setSheetState(() => pickedImage = null),
                                ),
                              ],
                            ),
                          )
                        else if (localImages.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              localImages.first,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Text(
                            l10n.noImageSelected,
                            style: TextStyle(
                              color: AbleTheme.textMuted(sheetContext),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (pickedVideo != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AbleTheme.panelFill(sheetContext),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AbleTheme.glassBorder(sheetContext),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.videocam_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.newVideoLabel(pickedVideo!.name),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AbleTheme.textMuted(sheetContext),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () =>
                                      setSheetState(() => pickedVideo = null),
                                ),
                              ],
                            ),
                          )
                        else if (localVideoUrl != null &&
                            localVideoUrl!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AbleTheme.panelFill(sheetContext),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_outline),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.currentVideoAttached,
                                  style: TextStyle(
                                    color: AbleTheme.textMuted(sheetContext),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final picker = ImagePicker();
                                        final image = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 85,
                                        );
                                        if (image == null) return;
                                        setSheetState(
                                            () => pickedImage = image);
                                      },
                                icon: const Icon(Icons.image_outlined),
                                label: Text(l10n.imageLabel),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final picker = ImagePicker();
                                        final video = await picker.pickVideo(
                                          source: ImageSource.gallery,
                                          maxDuration:
                                              const Duration(minutes: 2),
                                        );
                                        if (video == null) return;
                                        setSheetState(
                                            () => pickedVideo = video);
                                      },
                                icon: const Icon(Icons.videocam_outlined),
                                label: Text(l10n.videoLabel),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(sheetContext),
                                child: Text(l10n.cancel),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setSheetState(() => isSaving = true);
                                        await _savePostEdit(
                                          context,
                                          contentController.text.trim(),
                                          pickedImage,
                                          pickedVideo,
                                        );
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                      },
                                child: Text(isSaving ? l10n.saving : l10n.save),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    contentController.dispose();
  }

  Future<void> _savePostEdit(
    BuildContext context,
    String newContent,
    XFile? newImage,
    XFile? newVideo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final supabase = Supabase.instance.client;
      final viewer = await ref.read(viewerProvider.future);

      if (viewer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseLoginFirst)),
        );
        return;
      }

      if (newContent.isEmpty &&
          localImages.isEmpty &&
          newImage == null &&
          (localVideoUrl == null || localVideoUrl!.isEmpty) &&
          newVideo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.postCannotBeEmpty)),
        );
        return;
      }

      String? newImageUrl;
      String? newVideoUrl;

      if (newImage != null) {
        final bytes = await newImage.readAsBytes();
        final fileName =
            'images/${viewer.id}_${widget.post.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await supabase.storage.from('post-media').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        newImageUrl =
            supabase.storage.from('post-media').getPublicUrl(fileName);
      }

      if (newVideo != null) {
        final bytes = await newVideo.readAsBytes();

        final originalName = newVideo.name.toLowerCase();
        String extension = 'mp4';
        String contentType = 'video/mp4';

        if (originalName.endsWith('.mov')) {
          extension = 'mov';
          contentType = 'video/quicktime';
        } else if (originalName.endsWith('.webm')) {
          extension = 'webm';
          contentType = 'video/webm';
        }

        final fileName =
            'videos/${viewer.id}_${widget.post.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';

        await supabase.storage.from('post-media').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: contentType,
              ),
            );

        newVideoUrl =
            supabase.storage.from('post-media').getPublicUrl(fileName);
      }

      final updateData = <String, dynamic>{
        'content': newContent.isEmpty ? null : newContent,
      };

      if (newImageUrl != null) updateData['image_url'] = newImageUrl;
      if (newVideoUrl != null) updateData['video_url'] = newVideoUrl;

      await supabase.from('posts').update(updateData).eq('id', widget.post.id);

      if (!mounted) return;

      setState(() {
        localContent = newContent;
        if (newImageUrl != null) localImages = [newImageUrl];
        if (newVideoUrl != null) localVideoUrl = newVideoUrl;
      });

      ref.invalidate(postsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editFailedError(e.toString()))),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadFollowingUsersForShare(
    AppViewer viewer,
  ) async {
    final supabase = Supabase.instance.client;
    if (viewer.role != 'client') return [];

    final rows = await supabase
        .from('follows')
        .select(
          'followed_client_id, followed_tutor_id, '
          'followed_business_id, followed_charity_id',
        )
        .eq('follower_client_id', viewer.id);

    final ids = <String>{};
    for (final r in rows) {
      for (final v in [
        r['followed_client_id'],
        r['followed_tutor_id'],
        r['followed_business_id'],
        r['followed_charity_id'],
      ]) {
        if (v != null) ids.add(v.toString());
      }
    }

    if (ids.isEmpty) return [];

    final users = await supabase
        .from('app_users')
        .select('id, account_type, display_name, username, profile_pic_url')
        .inFilter('id', ids.toList());

    return [
      for (final u in users as List)
        {
          'id': u['id'].toString(),
          'user_type': u['account_type'].toString(),
          'full_name': u['display_name']?.toString() ?? 'User',
          'username': u['username']?.toString() ?? '',
          'profile_pic_url': u['profile_pic_url']?.toString(),
        }
    ];
  }

  Future<void> _sharePostInsideApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final viewer = await ref.read(viewerProvider.future);

      if (viewer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseLoginFirst)),
        );
        return;
      }

      final users = await _loadFollowingUsersForShare(viewer);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.65,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AbleTheme.textMuted(sheetContext).withOpacity(0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.shareToFollowing,
                    style: TextStyle(
                      color: AbleTheme.textPrimary(sheetContext),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: users.isEmpty
                        ? Center(
                            child: Text(
                              l10n.notFollowingAnyone,
                              style: TextStyle(
                                color: AbleTheme.textMuted(sheetContext),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final image =
                                  user['profile_pic_url']?.toString();
                              final name =
                                  user['full_name']?.toString() ?? 'User';
                              final username =
                                  user['username']?.toString() ?? '';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                leading: CircleAvatar(
                                  backgroundImage:
                                      image != null && image.isNotEmpty
                                          ? NetworkImage(image)
                                          : null,
                                  child: image == null || image.isEmpty
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'U',
                                        )
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    color: AbleTheme.textPrimary(sheetContext),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  username.isEmpty
                                      ? user['user_type'].toString()
                                      : '@$username',
                                  style: TextStyle(
                                    color: AbleTheme.textMuted(sheetContext),
                                  ),
                                ),
                                trailing: const Icon(Icons.send_rounded),
                                onTap: () async {
                                  try {
                                    await Supabase.instance.client.rpc(
                                      'share_post_to_user',
                                      params: {
                                        'p_sender_id': viewer.id,
                                        'p_sender_type': viewer.role,
                                        'p_receiver_id': user['id'],
                                        'p_receiver_type': user['user_type'],
                                        'p_post_id': widget.post.id,
                                      },
                                    );

                                    if (!mounted) return;
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.postShared),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            l10n.shareFailedError(e.toString())),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareFailedError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDeleted) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final post = widget.post;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBg =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE8F7FC);
    final primaryColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;
    final textColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;
    final hasProfileImage =
        post.authorImage != null && post.authorImage!.isNotEmpty;
    final hasPostImage = localImages.isNotEmpty;
    final hasPostVideo = localVideoUrl != null && localVideoUrl!.isNotEmpty;
    final showPostContent =
        _shouldShowPostContent(hasPostVideo: hasPostVideo);

    final viewerAsync = ref.watch(viewerProvider);
    final viewer = viewerAsync.maybeWhen(data: (v) => v, orElse: () => null);
    final isOwnPost = _isOwnPost(viewer);

    final followArgs = (targetId: post.authorId, targetType: post.postType);
    final followState = ref.watch(followStateProvider(followArgs));
    final showFollowUi = viewer != null &&
        viewer.role == 'client' &&
        !isOwnPost &&
        post.authorId.isNotEmpty &&
        post.postType.isNotEmpty;
    final cardColor =
        isDark ? const Color(0xFF101A2B) : Colors.white.withOpacity(0.98);

    
    final isAr = l10n.localeName == 'ar';
    final spokenParts = <String>[
      post.authorName ?? l10n.unknown,
      _roleLabel(l10n, post.postType),
      _formatPostTime(l10n, post.createdAt),
      if (showPostContent && localContent.trim().isNotEmpty) localContent,
    ];
    spokenParts.add(isAr
        ? '$localLikes إعجاب، $localComments تعليق'
        : '$localLikes likes, $localComments comments');
    final spokenText =
        spokenParts.where((p) => p.trim().isNotEmpty).join('. ');

    return VipGoldFrame(
      isVip: post.isVip,
      radius: 29,
      child: TtsWrapper(
      text: spokenText,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Avatar + Name + Follow + Menu ──
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        if (post.authorId.isNotEmpty &&
                            post.postType.isNotEmpty) {
                          context.push(
                            '/profile/${post.postType}/${post.authorId}',
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 23,
                        backgroundColor: avatarBg,
                        backgroundImage: hasProfileImage
                            ? NetworkImage(post.authorImage!)
                            : null,
                        child: hasProfileImage
                            ? null
                            : Text(
                                (post.authorName ?? 'A')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              if (post.authorId.isNotEmpty &&
                                  post.postType.isNotEmpty) {
                                context.push(
                                  '/profile/${post.postType}/${post.authorId}',
                                );
                              }
                            },
                            child: Text(
                              post.authorName ?? l10n.unknown,
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${_roleLabel(l10n, post.postType)} • ${_formatPostTime(l10n, post.createdAt)}',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.isVip) ...[
                                const SizedBox(width: 6),
                                const VipBadge(compact: true),
                              ],
                             
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (showFollowUi) ...[
                      const SizedBox(width: 6),
                      _buildFollowButton(
                        targetId: post.authorId,
                        targetType: post.postType,
                        primaryColor: primaryColor,
                        textColor: textColor,
                        isDark: isDark,
                      ),
                    ],
                    IconButton(
                      onPressed: () => _openPostMenu(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 42,
                        height: 42,
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: mutedColor,
                        size: 25,
                      ),
                    ),
                  ],
                ),

                // ── Tags ──
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: post.tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                ],

                if (hasPostImage) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      localImages.first,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],

                // ── Centered portrait video inside a black media frame ──
                if (hasPostVideo) ...[
                  const SizedBox(height: 15),
                  _PostPortraitVideoFrame(videoUrl: localVideoUrl!),
                ],

                // ── Hide fixed video-share text; keep real captions ──
                if (showPostContent) ...[
                  const SizedBox(height: 10),
                  _TranslatableContent(
                    content: localContent,
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ],

                // ── Donation button (charity only) ──
                if (post.postType == 'charity' &&
                    (post.donationLink ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DonationButton(
                    url: post.donationLink!.trim(),
                    isDark: isDark,
                    accentColor: primaryColor,
                  ),
                ],

                const SizedBox(height: 14),

                // ── Actions row: Like / Comment / Share / Save ──
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleLike(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: _Stat(
                          icon: localIsLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          label: '$localLikes',
                          isActive: localIsLiked,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openComments(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: _Stat(
                          icon: Icons.mode_comment_outlined,
                          label: '$localComments',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _sharePostInsideApp(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: _Stat(
                            icon: Icons.send_outlined, label: l10n.share),
                      ),
                    ),
                    const Spacer(),

                    // ── Save / Bookmark ──
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isSavingPost ? null : () => _toggleSave(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: localIsSaved
                              ? AbleTheme.accent(context).withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: isSavingPost
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AbleTheme.accent(context),
                                ),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                                child: Icon(
                                  localIsSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  key: ValueKey(localIsSaved),
                                  size: 22,
                                  color: localIsSaved
                                      ? AbleTheme.accent(context)
                                      : AbleTheme.textMuted(context),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Portrait video frame used inside the existing post card
// ─────────────────────────────────────────────

class _PostPortraitVideoFrame extends StatelessWidget {
  const _PostPortraitVideoFrame({required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameHeight =
            (constraints.maxWidth * 9 / 16).clamp(200.0, 400.0).toDouble();

        return ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Container(
            width: double.infinity,
            height: frameHeight,
            color: Colors.black,
            alignment: Alignment.center,
            child: PostVideoPlayer(
              videoUrl: videoUrl,
              maxHeight: frameHeight,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Translatable content widget
// ─────────────────────────────────────────────

class _TranslatableContent extends StatefulWidget {
  const _TranslatableContent({
    super.key,
    required this.content,
    required this.textColor,
    required this.mutedColor,
    this.compact = false,
  });

  final String content;
  final Color textColor;
  final Color mutedColor;
  final bool compact;

  @override
  State<_TranslatableContent> createState() => _TranslatableContentState();
}

class _TranslatableContentState extends State<_TranslatableContent> {
  bool _isTranslating = false;
  bool _isTranslated = false;
  String? _translatedText;
  String? _translatedLanguage;

  @override
  void didUpdateWidget(covariant _TranslatableContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.content != widget.content) {
      _isTranslating = false;
      _isTranslated = false;
      _translatedText = null;
      _translatedLanguage = null;
    }
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }

  TextDirection _directionFor(String value) {
    return _containsArabic(value) ? TextDirection.rtl : TextDirection.ltr;
  }

  String _extractTranslatedText(dynamic data) {
    final segments = data is List && data.isNotEmpty && data[0] is List
        ? data[0] as List
        : const [];

    return segments
        .whereType<List>()
        .where((part) => part.isNotEmpty && part[0] != null)
        .map((part) => part[0].toString())
        .join()
        .trim();
  }

  Future<void> _toggleTranslate() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isTranslating) return;

    if (_isTranslated) {
      setState(() => _isTranslated = false);
      return;
    }

    if ((_translatedText ?? '').isNotEmpty) {
      setState(() => _isTranslated = true);
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final encodedText = Uri.encodeComponent(widget.content);

      final detectionUrl = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx&sl=auto&tl=en&dt=t&q=$encodedText',
      );

      final detectionResponse =
          await http.get(detectionUrl).timeout(const Duration(seconds: 10));

      if (detectionResponse.statusCode != 200) {
        throw Exception('Translation service unavailable.');
      }

      final detectionData = jsonDecode(detectionResponse.body);
      final sourceLanguage = detectionData[2]?.toString() ?? 'en';
      final targetLanguage = sourceLanguage == 'ar' ? 'en' : 'ar';

      String translatedText;

      if (targetLanguage == 'en') {
        translatedText = _extractTranslatedText(detectionData);
      } else {
        final translationUrl = Uri.parse(
          'https://translate.googleapis.com/translate_a/single'
          '?client=gtx&sl=auto&tl=ar&dt=t&q=$encodedText',
        );

        final translationResponse =
            await http.get(translationUrl).timeout(const Duration(seconds: 10));

        if (translationResponse.statusCode != 200) {
          throw Exception('Translation service unavailable.');
        }

        translatedText =
            _extractTranslatedText(jsonDecode(translationResponse.body));
      }

      if (translatedText.isEmpty) {
        throw Exception('No translation returned.');
      }

      if (!mounted) return;

      setState(() {
        _translatedText = translatedText;
        _translatedLanguage = targetLanguage;
        _isTranslated = true;
      });
    } catch (e) {
      debugPrint('TRANSLATION ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotTranslate)),
      );
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayedText =
        _isTranslated ? (_translatedText ?? widget.content) : widget.content;

    final textDirection = _isTranslated
        ? (_translatedLanguage == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr)
        : _directionFor(widget.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: textDirection,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: TtsWrapper(
              text: displayedText,
              child: Text(
                displayedText,
                key: ValueKey('${_isTranslated}_$displayedText'),
                textAlign: textDirection == TextDirection.rtl
                    ? TextAlign.right
                    : TextAlign.left,
                style: TextStyle(
                  height: widget.compact ? 1.4 : 1.55,
                  fontSize: widget.compact ? 13.5 : null,
                  color: widget.textColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isTranslating ? null : _toggleTranslate,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _isTranslating
                  ? SizedBox(
                      height: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: widget.mutedColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.translating,
                            style: TextStyle(
                              color: widget.mutedColor,
                              fontSize: widget.compact ? 11.5 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TtsWrapper(
                      text: _isTranslated ? l10n.seeOriginal : l10n.seeTranslation,
                      child: Text(
                        _isTranslated ? l10n.seeOriginal : l10n.seeTranslation,
                        style: TextStyle(
                          color: widget.mutedColor,
                          fontSize: widget.compact ? 11.5 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Comments Sheet
// ─────────────────────────────────────────────

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({
    required this.postId,
    required this.postAuthorId,
    required this.postAuthorRole,
    required this.onCommentAdded,
    required this.onCommentDeleted,
  });

  final String postId;
  final String postAuthorId;
  final String postAuthorRole;
  final VoidCallback onCommentAdded;
  final VoidCallback onCommentDeleted;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final TextEditingController commentController = TextEditingController();

  bool isLoading = true;
  bool isSending = false;
  String? errorMessage;
  List<_PostComment> comments = [];

  AppViewer? viewer;

  @override
  void initState() {
    super.initState();
    _initCommentsSheet();
  }

  Future<void> _initCommentsSheet() async {
    viewer = await ref.read(viewerProvider.future);
    await _loadComments();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  String _formatPostTime(AppLocalizations l10n, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return l10n.justNow;
    if (difference.inMinutes < 60) return l10n.minutesAgo(difference.inMinutes);
    if (difference.inHours < 24) return l10n.hoursAgo(difference.inHours);
    if (difference.inDays < 7) return l10n.daysAgo(difference.inDays);

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _loadComments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final rows = await supabase
          .from('post_comments')
          .select(
            'id, post_id, comment_text, created_at, '
            'client_id, tutor_id, business_id, charity_id',
          )
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      final authorIds = <String>{};
      for (final r in rows) {
        for (final v in [
          r['client_id'],
          r['tutor_id'],
          r['business_id'],
          r['charity_id'],
        ]) {
          if (v != null) authorIds.add(v.toString());
        }
      }

      final authorsMap = <String, Map<String, dynamic>>{};
      if (authorIds.isNotEmpty) {
        final authors = await supabase
            .from('app_users')
            .select(
                'id, account_type, display_name, username, profile_pic_url')
            .inFilter('id', authorIds.toList());

        for (final a in authors as List) {
          authorsMap[a['id'].toString()] = a as Map<String, dynamic>;
        }
      }

      final loaded = <_PostComment>[];
      for (final r in rows) {
        String? authorId;
        String role = '';
        if (r['client_id'] != null) {
          authorId = r['client_id'].toString();
          role = 'client';
        } else if (r['tutor_id'] != null) {
          authorId = r['tutor_id'].toString();
          role = 'tutor';
        } else if (r['business_id'] != null) {
          authorId = r['business_id'].toString();
          role = 'business';
        } else if (r['charity_id'] != null) {
          authorId = r['charity_id'].toString();
          role = 'charity';
        }

        final author = authorId != null ? authorsMap[authorId] : null;

        loaded.add(_PostComment(
          id: r['id'].toString(),
          postId: r['post_id'].toString(),
          commentText: r['comment_text']?.toString() ?? '',
          createdAt: DateTime.parse(r['created_at'].toString()).toLocal(),
          authorId: authorId ?? '',
          authorRole: role,
          authorName: author?['display_name']?.toString() ??
              author?['username']?.toString() ??
              'User',
          authorImage: author?['profile_pic_url']?.toString(),
        ));
      }

      if (!mounted) return;
      setState(() {
        comments = loaded;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  bool _canEditComment(_PostComment comment) {
    final v = viewer;
    if (v == null) return false;
    return v.id == comment.authorId && v.role == comment.authorRole;
  }

  bool _canDeleteComment(_PostComment comment) {
    final v = viewer;
    if (v == null) return false;
    return v.id == widget.postAuthorId && v.role == widget.postAuthorRole;
  }

  Future<void> _editComment(_PostComment comment) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: comment.commentText);

    final newText = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.editComment),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(hintText: l10n.commentDialogHint),
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

    if (newText == null || newText.isEmpty || newText == comment.commentText) {
      return;
    }

    try {
      await Supabase.instance.client
          .from('post_comments')
          .update({'comment_text': newText}).eq('id', comment.id);

      if (!mounted) return;

      setState(() {
        comments = comments.map((item) {
          if (item.id == comment.id) return item.copyWith(commentText: newText);
          return item;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commentUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editCommentFailedError(e.toString()))),
      );
    }
  }

  Future<void> _deleteComment(_PostComment comment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteCommentQuestion),
        content: Text(l10n.deleteCommentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('post_comments').delete().eq('id', comment.id);

      if (!mounted) return;

      setState(() => comments.removeWhere((item) => item.id == comment.id));

      widget.onCommentDeleted();

      ref.invalidate(postsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commentDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteCommentFailedError(e.toString()))),
      );
    }
  }

  Future<void> _sendComment() async {
    final l10n = AppLocalizations.of(context)!;
    final text = commentController.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() => isSending = true);

    try {
      final supabase = Supabase.instance.client;
      final currentViewer = viewer ?? await ref.read(viewerProvider.future);

      if (currentViewer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseLoginFirst)),
        );
        return;
      }

      viewer = currentViewer;

      final inserted = await supabase
          .from('post_comments')
          .insert({
            'post_id': widget.postId,
            currentViewer.userColumn: currentViewer.id,
            'comment_text': text,
          })
          .select()
          .single();

      final receiverAuthId = await _lookupAuthorAuthId(
          widget.postAuthorId, widget.postAuthorRole);

      if (receiverAuthId != null &&
          receiverAuthId != currentViewer.authUserId) {
        await supabase.from('notifications').insert({
          'type': 'comment',
          'title': 'New comment',
          'message': '${currentViewer.username} commented on your post',
          'related_user_id': currentViewer.authUserId,
          'related_post_id': widget.postId,
          'receiver_id': receiverAuthId,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      final newComment = _PostComment(
        id: inserted['id'].toString(),
        postId: inserted['post_id'].toString(),
        commentText: inserted['comment_text']?.toString() ?? text,
        createdAt: DateTime.parse(inserted['created_at'].toString()).toLocal(),
        authorId: currentViewer.id,
        authorRole: currentViewer.role,
        authorName: currentViewer.username,
        authorImage: currentViewer.profileImage,
      );

      if (!mounted) return;
      setState(() {
        comments.add(newComment);
        commentController.clear();
      });

      widget.onCommentAdded();

      ref.invalidate(postsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
    } catch (e) {
      debugPrint('COMMENT ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commentFailedError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF182437) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: AbleTheme.textMuted(context).withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TtsWrapper(
                  text: l10n.commentsTitle,
                  child: Text(
                    l10n.commentsTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AbleTheme.textPrimary(context),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: AbleTheme.textMuted(context)),
                          ),
                        )
                      : comments.isEmpty
                          ? Center(
                              child: TtsWrapper(
                                text: l10n.noCommentsYetPeriod,
                                child: Text(
                                  l10n.noCommentsYetPeriod,
                                  style: TextStyle(
                                      color: AbleTheme.textMuted(context)),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: comments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                return _CommentTile(
                                  comment: comment,
                                  timeText:
                                      _formatPostTime(l10n, comment.createdAt),
                                  canEdit: _canEditComment(comment),
                                  canDelete: _canDeleteComment(comment),
                                  onEdit: () => _editComment(comment),
                                  onDelete: () => _deleteComment(comment),
                                );
                              },
                            ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.addACommentHint,
                      filled: true,
                      fillColor: AbleTheme.panelFill(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: AbleTheme.glassBorder(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: AbleTheme.glassBorder(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: AbleTheme.accent(context)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: AbleTheme.primary(context),
                  child: IconButton(
                    onPressed: isSending ? null : _sendComment,
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Comment Tile
// ─────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.timeText,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final _PostComment comment;
  final String timeText;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  void _openAuthorProfile(BuildContext context) {
    if (comment.authorRole.isEmpty || comment.authorId.isEmpty) return;

    Navigator.pop(context);
    context.push(
      '/profile/${comment.authorRole}/${comment.authorId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImage =
        comment.authorImage != null && comment.authorImage!.isNotEmpty;
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AbleTheme.panelFill(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AbleTheme.glassBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => _openAuthorProfile(context),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AbleTheme.iconBubble(context),
              backgroundImage:
                  hasImage ? NetworkImage(comment.authorImage!) : null,
              child: hasImage
                  ? null
                  : Text(
                      comment.authorName.isNotEmpty
                          ? comment.authorName[0].toUpperCase()
                          : 'A',
                      style: TextStyle(
                        color: AbleTheme.accent(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _openAuthorProfile(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            comment.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                _TranslatableContent(
                  key: ValueKey(
                    'comment_translation_${comment.id}_${comment.commentText}',
                  ),
                  content: comment.commentText,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  compact: true,
                ),
              ],
            ),
          ),
          if (canEdit || canDelete)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                if (canEdit)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined),
                        const SizedBox(width: 8),
                        Text(l10n.editCommentMenu),
                      ],
                    ),
                  ),
                if (canDelete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          l10n.deleteCommentMenu,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
              ],
              icon: Icon(
                Icons.more_horiz_rounded,
                color: mutedColor,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stat widget (like / comment / share)
// ─────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, this.isActive = false});

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isActive
        ? AbleColors.danger
        : isDark
            ? AbleColors.darkSecondary
            : AbleColors.lightPrimaryDark;
    final textColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: textColor)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PostComment model
// ─────────────────────────────────────────────

class _PostComment {
  final String id;
  final String postId;
  final String commentText;
  final DateTime createdAt;
  final String authorId;
  final String authorRole;
  final String authorName;
  final String? authorImage;

  const _PostComment({
    required this.id,
    required this.postId,
    required this.commentText,
    required this.createdAt,
    required this.authorId,
    required this.authorRole,
    required this.authorName,
    required this.authorImage,
  });

  _PostComment copyWith({String? commentText}) {
    return _PostComment(
      id: id,
      postId: postId,
      commentText: commentText ?? this.commentText,
      createdAt: createdAt,
      authorId: authorId,
      authorRole: authorRole,
      authorName: authorName,
      authorImage: authorImage,
    );
  }
}

// ─────────────────────────────────────────────
// Helper: look up auth_user_id of a post author
// ─────────────────────────────────────────────

Future<String?> _lookupAuthorAuthId(String userId, String role) async {
  if (userId.isEmpty || role.isEmpty) return null;
  try {
    final row = await Supabase.instance.client
        .from('app_users')
        .select('auth_user_id')
        .eq('id', userId)
        .eq('account_type', role)
        .maybeSingle();
    return row?['auth_user_id']?.toString();
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────
// Donation Button (charity posts)
// ─────────────────────────────────────────────

class _DonationButton extends StatelessWidget {
  const _DonationButton({
    required this.url,
    required this.isDark,
    required this.accentColor,
  });

  final String url;
  final bool isDark;
  final Color accentColor;

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    var normalized = url;
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidDonationLink)),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenDonationLink)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0992C2), Color(0xFF0AC4E0)],
          )
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF0B82D2),
              Color(0xFF45AEDD),
              Color(0xFF7BD8E8),
            ],
          );

    return TtsWrapper(
      text: l10n.donateNow,
      child: SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.22),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _open(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          icon: const Icon(Icons.favorite_rounded, size: 18),
          label: Text(
            l10n.donateNow,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
      ),
    );
  }
}