import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ableplusproject/Models/PostModel.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/vip_provider.dart';
import 'package:ableplusproject/screens/Home/postcard.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  const PostDetailsScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  late Future<PostModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPost();
  }

  /// Single-post load — uses the same posts_feed view as the feed.
  /// Total queries: 2 (1 for the post + media, 1 for like status).
  Future<PostModel?> _loadPost() async {
    final supabase = Supabase.instance.client;

    final row = await supabase
        .from('posts_feed')
        .select(
          '*, media!media_post_id_fkey(file_url, file_type, media_type)',
        )
        .eq('id', widget.postId)
        .maybeSingle();

    if (row == null) return null;

    // Like status
    bool isLiked = false;
    final viewer = await ref.read(viewerProvider.future);
    if (viewer != null) {
      try {
        final liked = await supabase
            .from('post_likes')
            .select('id')
            .eq('post_id', widget.postId)
            .eq(viewer.userColumn, viewer.id)
            .maybeSingle();
        isLiked = liked != null;
      } catch (_) {}
    }

    // Extract media
    final media = (row['media'] as List?) ?? const [];
    final images = <String>[];
    String? videoUrl = row['video_url']?.toString();

    for (final m in media) {
      final mm = m as Map<String, dynamic>;
      if (mm['media_type'] != 'post') continue;
      final url = mm['file_url']?.toString();
      if (url == null || url.isEmpty) continue;
      if (mm['file_type'] == 'image') {
        images.add(url);
      } else if (mm['file_type'] == 'video' &&
          (videoUrl == null || videoUrl.isEmpty)) {
        videoUrl = url;
      }
    }

    final extraImage = row['image_url']?.toString();
    if (extraImage != null &&
        extraImage.isNotEmpty &&
        !images.contains(extraImage)) {
      images.add(extraImage);
    }

    final authorId = row['author_id']?.toString() ?? '';
    final authorType = row['author_type']?.toString() ?? 'unknown';
    final activeVip = await ref.read(activeVipProvidersProvider.future);
    final vipStatus = activeVip[vipKey(authorType, authorId)];

    return PostModel(
      id: row['id'].toString(),
      authorId: authorId,
      authorName: row['author_name']?.toString() ?? 'Unknown',
      authorImage: row['author_image']?.toString(),
      content: row['content']?.toString() ?? '',
      images: images,
      videoUrl: (videoUrl != null && videoUrl.isNotEmpty) ? videoUrl : null,
      postType: authorType,
      tags: const [],
      createdAt: DateTime.parse(row['created_at'].toString()).toLocal(),
      likes: (row['likes_count'] as num?)?.toInt() ?? 0,
      comments: (row['comments_count'] as num?)?.toInt() ?? 0,
      isLiked: isLiked,
      donationLink: row['donation_link']?.toString(),
      isVip: vipStatus != null,
      vipExpiresAt: vipStatus?.expiresAt.toLocal(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadPost();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mutedColor = AbleTheme.textMuted(context);

    return AbleScaffold(
      title: l10n.postTitle,
      currentIndex: 0,
      showBackButton: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<PostModel?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.error_outline, size: 48, color: mutedColor),
                  const SizedBox(height: 12),
                  Center(
                    child: TtsWrapper(
                      text: l10n.couldNotLoadPost(snapshot.error.toString()),
                      child: Text(
                        l10n.couldNotLoadPost(snapshot.error.toString()),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mutedColor),
                      ),
                    ),
                  ),
                ],
              );
            }

            final post = snapshot.data;
            if (post == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.search_off_rounded, size: 56, color: mutedColor),
                  const SizedBox(height: 12),
                  Center(
                    child: TtsWrapper(
                      text: '${l10n.postNoLongerAvailableNotif}. ${l10n.postDeletedByAuthor}',
                      child: Text(
                        l10n.postNoLongerAvailableNotif,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      l10n.postDeletedByAuthor,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedColor, fontSize: 13),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              children: [PostCard(post: post)],
            );
          },
        ),
      ),
    );
  }
}