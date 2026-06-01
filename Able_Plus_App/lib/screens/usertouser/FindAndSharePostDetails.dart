import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class FindAndSharePostDetailsScreen extends ConsumerStatefulWidget {
  final String postId;

  const FindAndSharePostDetailsScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<FindAndSharePostDetailsScreen> createState() =>
      _FindAndSharePostDetailsScreenState();
}

class _FindAndSharePostDetailsScreenState
    extends ConsumerState<FindAndSharePostDetailsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  late Future<_PostBundle> postFuture;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _initializedVideoUrl;
  bool _videoLoading = false;
  String? _videoError;

  AppViewer? _viewer;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    postFuture = _loadAll();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  /// ~10 queries → 2.
  /// 1. Cached viewer via viewerProvider (often 0 queries).
  /// 2. ONE query for the post.
  /// 3. ONE query for the author via app_users (or 0 if no author).
  Future<_PostBundle> _loadAll() async {
    _viewer = await ref.read(viewerProvider.future);

    final post = await supabase
        .from('community_posts')
        .select('id, description, image_url, video_url, '
            'created_at, user_id, account_id, account_type')
        .eq('id', widget.postId)
        .maybeSingle();

    if (post == null) {
      throw Exception('Post not found');
    }

    final accountId = post['account_id']?.toString();
    final accountTypeRaw = post['account_type']?.toString() ?? '';
    final accountTypeSingular = _normalizeAccountType(accountTypeRaw);

    String? avatarUrl;
    String ownerName = 'User';

    if (accountId != null && accountId.isNotEmpty) {
      final author = await supabase
          .from('app_users')
          .select('display_name, profile_pic_url')
          .eq('id', accountId)
          .eq('account_type', accountTypeSingular)
          .maybeSingle();

      if (author != null) {
        avatarUrl = author['profile_pic_url']?.toString();
        ownerName = author['display_name']?.toString() ?? 'User';
      }
    }

    return _PostBundle(
      post: Map<String, dynamic>.from(post),
      avatarUrl: avatarUrl,
      ownerName: ownerName,
      ownerAccountId: accountId,
      ownerAccountType: accountTypeSingular,
    );
  }

  String _normalizeAccountType(String t) {
    switch (t) {
      case 'clients':
        return 'client';
      case 'tutors':
        return 'tutor';
      case 'businesses':
        return 'business';
      case 'charities':
        return 'charity';
      default:
        return t;
    }
  }

  bool _isOwner(_PostBundle bundle) {
    final viewer = _viewer;
    if (viewer == null) return false;

    final ownerId = bundle.ownerAccountId;
    final ownerType = bundle.ownerAccountType;

    if (ownerId == null || ownerType == null) {
      final postUserId = bundle.post['user_id']?.toString();
      return postUserId != null && postUserId == viewer.authUserId;
    }

    return ownerId == viewer.id && ownerType == viewer.role;
  }

  Future<void> _initVideoIfNeeded(String videoUrl) async {
    if (_initializedVideoUrl == videoUrl) return;
    if (_videoLoading) return;

    _videoLoading = true;

    try {
      await _videoController?.dispose();
      _chewieController?.dispose();

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xff4a90e2),
          handleColor: const Color(0xff4a90e2),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );

      _initializedVideoUrl = videoUrl;
      _videoError = null;
    } catch (e) {
      _videoError = e.toString();
    } finally {
      _videoLoading = false;
      if (mounted) setState(() {});
    }
  }

  Widget _buildVideoSection(String videoUrl) {
    final l10n = AppLocalizations.of(context)!;
    if (_initializedVideoUrl != videoUrl &&
        !_videoLoading &&
        _videoError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initVideoIfNeeded(videoUrl);
      });
    }

    if (_videoError != null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 36),
                const SizedBox(height: 8),
                Text(
                  l10n.couldNotLoadVideo,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_chewieController == null ||
        _videoController == null ||
        !_videoController!.value.isInitialized) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildPostImage(String imageUrl) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                width: 200,
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 180,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_outlined,
                        size: 40, color: Colors.black38),
                    const SizedBox(height: 8),
                    Text(
                      l10n.couldNotLoadImage,
                      style: const TextStyle(color: Colors.black54),
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

  Widget _buildProfileAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xff4a90e2),
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return const CircleAvatar(
      radius: 22,
      backgroundColor: Color(0xff4a90e2),
      child: Icon(Icons.person_outline, color: Colors.white),
    );
  }

  Future<void> _contactOwner(_PostBundle bundle) async {
    final l10n = AppLocalizations.of(context)!;
    final viewer = _viewer;

    if (viewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mustBeSignedInToMessage),
        ),
      );
      return;
    }

    final ownerAccountId = bundle.ownerAccountId;
    final ownerAccountType = bundle.ownerAccountType;

    if (ownerAccountId == null ||
        ownerAccountId.isEmpty ||
        ownerAccountType == null ||
        ownerAccountType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ownerInfoMissing)),
      );
      return;
    }

    if (ownerAccountId == viewer.id && ownerAccountType == viewer.role) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotMessageOwnPost)),
      );
      return;
    }

    try {
      // ONE RPC replaces 2-3 conversation lookup/insert queries.
      final conversationId = await supabase.rpc(
        'get_or_create_conversation',
        params: {
          'p_my_id': viewer.id,
          'p_my_type': viewer.role,
          'p_other_id': ownerAccountId,
          'p_other_type': ownerAccountType,
        },
      );

      if (!mounted) return;

      context.push(
        '/chat',
        extra: {
          'conversationId': conversationId.toString(),
          'otherName': bundle.ownerName,
          'otherId': ownerAccountId,
          'otherType': ownerAccountType,
          'otherImage': bundle.avatarUrl,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenChat(e.toString()))),
      );
    }
  }

  Future<void> _deletePost(_PostBundle bundle) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isOwner(bundle)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deletePostQuestionFs),
        content: Text(l10n.deletePostBodyFs),
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

    setState(() {
      _isDeleting = true;
    });

    try {
      final deleted = await supabase
          .from('community_posts')
          .delete()
          .eq('id', widget.postId)
          .select();

      if (!mounted) return;

      if (deleted.isEmpty) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Delete blocked by database policy (RLS). Check Supabase policies for community_posts.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postDeleted)),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home/Findandshare');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deletePostFailedError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AbleScaffold(
      title: l10n.findAndSharePostDetails,
      showBackButton: true,
      body: FutureBuilder<_PostBundle>(
        future: postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '${l10n.error}: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bundle = snapshot.data!;
          final post = bundle.post;

          final description = post['description']?.toString() ?? '';
          final imageUrl = post['image_url']?.toString() ?? '';
          final videoUrl = post['video_url']?.toString() ?? '';

          final hasImage = imageUrl.isNotEmpty;
          final hasVideo = videoUrl.isNotEmpty;
          final isOwner = _isOwner(bundle);

          // ── النص المنطوق لتفاصيل البوست ──
          final spokenParts = <String>[
            bundle.ownerName,
            l10n.descriptionLabel,
            if (description.trim().isNotEmpty) description,
          ];
          final spokenText =
              spokenParts.where((p) => p.trim().isNotEmpty).join('. ');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              if (hasImage) ...[
                _buildPostImage(imageUrl),
                const SizedBox(height: 14),
              ],
              if (hasVideo) ...[
                _buildVideoSection(videoUrl),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 6),
              TtsWrapper(
                text: spokenText,
                child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildProfileAvatar(bundle.avatarUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Chip(label: Text(bundle.ownerName)),
                        ),
                        if (isOwner)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Color(0xff33496d)),
                            onSelected: (value) {
                              if (value == 'delete') _deletePost(bundle);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'delete',
                                enabled: !_isDeleting,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: _isDeleting
                                          ? Colors.grey
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isDeleting
                                          ? l10n.deletingPost
                                          : l10n.deletePost,
                                      style: TextStyle(
                                        color: _isDeleting
                                            ? Colors.grey
                                            : Colors.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.descriptionLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff33496d),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: Color(0xff33496d),
                      ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 20),
              TtsWrapper(
                text: l10n.contactOwner,
                child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _contactOwner(bundle),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(
                    l10n.contactOwner,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4a90e2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostBundle {
  final Map<String, dynamic> post;
  final String? avatarUrl;
  final String ownerName;
  final String? ownerAccountId;
  final String? ownerAccountType;

  const _PostBundle({
    required this.post,
    required this.avatarUrl,
    required this.ownerName,
    required this.ownerAccountId,
    required this.ownerAccountType,
  });
}