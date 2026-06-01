import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ableplusproject/Models/PostModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vip_provider.dart';

/// Feed filter used by Home/community feed.
enum FeedFilter { all, following }

final feedFilterProvider = StateProvider<FeedFilter>((ref) => FeedFilter.all);

// ─────────────────────────────────────────────
// Shared viewer info (cached by Riverpod)
// ─────────────────────────────────────────────

/// One row per logged-in user, fetched once via `current_viewer()` RPC.
///
/// Re-used by Post_provider, PostCard, PostDetailsScreen, home avatar, etc.
/// Invalidate this provider after sign-in/sign-out.
class AppViewer {
  final String id;
  final String authUserId;
  final String role; // 'client' | 'tutor' | 'business' | 'charity'
  final String username;
  final String displayName;
  final String? profileImage;

  const AppViewer({
    required this.id,
    required this.authUserId,
    required this.role,
    required this.username,
    required this.displayName,
    required this.profileImage,
  });

  /// Column name in tables that have a `<role>_id` foreign key.
  String get userColumn => '${role}_id';

  /// Name of the table for this role.
  String get table {
    switch (role) {
      case 'client':
        return 'clients';
      case 'tutor':
        return 'tutors';
      case 'business':
        return 'businesses';
      case 'charity':
        return 'charities';
      default:
        return 'clients';
    }
  }
}

final viewerProvider = FutureProvider<AppViewer?>((ref) async {
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentUser == null) return null;

  // ONE call to the database. Replaces 4 sequential email lookups + profile fetch.
  final rows = await supabase.rpc('current_viewer');
  if (rows is! List || rows.isEmpty) return null;

  final row = rows.first as Map<String, dynamic>;
  return AppViewer(
    id: row['id'].toString(),
    authUserId: row['auth_user_id']?.toString() ?? '',
    role: row['account_type']?.toString() ?? 'client',
    username: row['username']?.toString() ?? 'User',
    displayName: row['display_name']?.toString() ?? 'User',
    profileImage: row['profile_pic_url']?.toString(),
  );
});

// ─────────────────────────────────────────────
// Posts provider
// ─────────────────────────────────────────────

final postsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final filter = ref.watch(feedFilterProvider);
  final viewer = await ref.watch(viewerProvider.future);
  final activeVip = await ref.watch(activeVipProvidersProvider.future);

  // 1) Following set — only needed for personalization
  final followingIds = <String>{};
  if (viewer != null) {
    final follows = await supabase
        .from('follows')
        .select(
          'followed_client_id, followed_tutor_id, '
          'followed_business_id, followed_charity_id',
        )
        .eq('follower_client_id', viewer.id);

    for (final f in follows) {
      for (final id in [
        f['followed_client_id'],
        f['followed_tutor_id'],
        f['followed_business_id'],
        f['followed_charity_id'],
      ]) {
        if (id != null) followingIds.add(id.toString());
      }
    }
  }

  // 2) ONE query: posts + author + counts (via posts_feed view) +
  //    embedded media. This replaces ~6 queries per post.
  final feedRows = await supabase
      .from('posts_feed')
      .select(
        '*, '
        'media!media_post_id_fkey(file_url, file_type, media_type)',
      )
      .order('created_at', ascending: false);

  // 3) ONE query for the viewer's likes across this entire feed.
  //    Lets us decide isLiked per post without N+1.
  final likedSet = <String>{};
  if (viewer != null && (feedRows as List).isNotEmpty) {
    final postIds =
        feedRows.map((r) => r['id'].toString()).toList(growable: false);

    final likedRows = await supabase
        .from('post_likes')
        .select('post_id')
        .inFilter('post_id', postIds)
        .eq(viewer.userColumn, viewer.id);

    for (final r in likedRows) {
      likedSet.add(r['post_id'].toString());
    }
  }

  // Build PostModels purely in Dart now — no more queries.
  PostModel? buildPost(Map<String, dynamic> row) {
    try {
      final postId = row['id'].toString();
      final authorId = row['author_id']?.toString() ?? '';
      final authorType = row['author_type']?.toString() ?? 'unknown';

      // Extract images + first video from embedded media.
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

      return PostModel(
        id: postId,
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
        isLiked: likedSet.contains(postId),
        donationLink: row['donation_link']?.toString(),
        isVip: activeVip.containsKey(vipKey(authorType, authorId)),
        vipExpiresAt: activeVip[vipKey(authorType, authorId)]?.expiresAt.toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  // 4) Filter / mix
  final all = <PostModel>[];
  for (final row in feedRows as List) {
    final post = buildPost(row as Map<String, dynamic>);
    if (post != null) all.add(post);
  }

  all.sort(_compareVipPosts);

  if (filter == FeedFilter.following) {
    if (viewer == null) return [];
    return all
        .where((p) => p.authorId == viewer.id || followingIds.contains(p.authorId))
        .toList();
  }

  // "All" feed = mix of following + discover
  final followingPosts = <PostModel>[];
  final discoverPosts = <PostModel>[];

  for (final p in all) {
    if (viewer != null &&
        (p.authorId == viewer.id || followingIds.contains(p.authorId))) {
      followingPosts.add(p);
    } else {
      discoverPosts.add(p);
    }
  }

  final mixed = _mixFeed(followingPosts: followingPosts, discoverPosts: discoverPosts);
  mixed.sort(_compareVipPosts);
  return mixed;
});

/// Charity-only feed used by the Charities screen.
final charityPostsProvider =
    FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final viewer = await ref.watch(viewerProvider.future);
  final activeVip = await ref.watch(activeVipProvidersProvider.future);

  // ONE query — same view, filtered by author_type.
  final feedRows = await supabase
      .from('posts_feed')
      .select(
        '*, media!media_post_id_fkey(file_url, file_type, media_type)',
      )
      .eq('author_type', 'charity')
      .order('created_at', ascending: false);

  // ONE query for the viewer's likes against this set.
  final likedSet = <String>{};
  if (viewer != null && (feedRows as List).isNotEmpty) {
    final postIds = feedRows.map((r) => r['id'].toString()).toList();
    final likedRows = await supabase
        .from('post_likes')
        .select('post_id')
        .inFilter('post_id', postIds)
        .eq(viewer.userColumn, viewer.id);
    for (final r in likedRows) {
      likedSet.add(r['post_id'].toString());
    }
  }

  final posts = <PostModel>[];

  for (final raw in feedRows as List) {
    final row = raw as Map<String, dynamic>;
    final postId = row['id'].toString();

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

    posts.add(PostModel(
      id: postId,
      authorId: row['author_id']?.toString() ?? '',
      authorName: row['author_name']?.toString() ?? 'Charity',
      authorImage: row['author_image']?.toString(),
      content: row['content']?.toString() ?? '',
      images: images,
      videoUrl: (videoUrl != null && videoUrl.isNotEmpty) ? videoUrl : null,
      postType: 'charity',
      tags: const [],
      createdAt: DateTime.parse(row['created_at'].toString()).toLocal(),
      likes: (row['likes_count'] as num?)?.toInt() ?? 0,
      comments: (row['comments_count'] as num?)?.toInt() ?? 0,
      isLiked: likedSet.contains(postId),
      donationLink: row['donation_link']?.toString(),
      isVip: activeVip.containsKey(vipKey('charity', row['author_id']?.toString() ?? '')),
      vipExpiresAt: activeVip[vipKey('charity', row['author_id']?.toString() ?? '')]?.expiresAt.toLocal(),
    ));
  }

  posts.sort(_compareVipPosts);
  return posts;
});

int _compareVipPosts(PostModel a, PostModel b) {
  if (a.isVip != b.isVip) return a.isVip ? -1 : 1;
  return b.createdAt.compareTo(a.createdAt);
}

List<PostModel> _mixFeed({
  required List<PostModel> followingPosts,
  required List<PostModel> discoverPosts,
}) {
  if (followingPosts.isEmpty) return discoverPosts;
  if (discoverPosts.isEmpty) return followingPosts;

  final result = <PostModel>[];
  int fi = 0;
  int di = 0;

  while (fi < followingPosts.length || di < discoverPosts.length) {
    for (int i = 0; i < 7 && fi < followingPosts.length; i++, fi++) {
      result.add(followingPosts[fi]);
    }
    for (int i = 0; i < 3 && di < discoverPosts.length; i++, di++) {
      result.add(discoverPosts[di]);
    }
  }

  return result;
}

// ─────────────────────────────────────────────
// Follow state — unchanged logic, but now uses viewerProvider
// ─────────────────────────────────────────────

class FollowState {
  final bool isFollowing;
  final bool isLoading;

  const FollowState({required this.isFollowing, required this.isLoading});

  FollowState copyWith({bool? isFollowing, bool? isLoading}) {
    return FollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FollowNotifier extends StateNotifier<FollowState> {
  final String targetId;
  final String targetType;
  final Ref ref;

  FollowNotifier({
    required this.ref,
    required this.targetId,
    required this.targetType,
  }) : super(const FollowState(isFollowing: false, isLoading: true)) {
    _init();
  }

  String get _followedColumn => 'followed_${targetType}_id';

  Future<void> _init() async {
    try {
      final viewer = await ref.read(viewerProvider.future);
      if (viewer == null || targetId.isEmpty || targetType.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      if (viewer.role == targetType && viewer.id == targetId) {
        state = const FollowState(isFollowing: false, isLoading: false);
        return;
      }

      final row = await Supabase.instance.client
          .from('follows')
          .select('id')
          .eq('follower_client_id', viewer.id)
          .eq(_followedColumn, targetId)
          .maybeSingle();

      state = FollowState(isFollowing: row != null, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggle() async {
    if (state.isLoading) return;
    final viewer = await ref.read(viewerProvider.future);
    if (viewer == null || targetId.isEmpty || targetType.isEmpty) return;

    if (viewer.role == targetType && viewer.id == targetId) {
      state = const FollowState(isFollowing: false, isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final supabase = Supabase.instance.client;
      if (state.isFollowing) {
        await supabase
            .from('follows')
            .delete()
            .eq('follower_client_id', viewer.id)
            .eq(_followedColumn, targetId);
        state = const FollowState(isFollowing: false, isLoading: false);
      } else {
        await supabase.from('follows').insert({
          'follower_client_id': viewer.id,
          _followedColumn: targetId,
        });

        // Follow notification — single query to app_users for the target's auth_user_id
        try {
          final target = await supabase
              .from('app_users')
              .select('auth_user_id')
              .eq('id', targetId)
              .eq('account_type', targetType)
              .maybeSingle();

          final receiverAuthId = target?['auth_user_id']?.toString();
          if (receiverAuthId != null &&
              receiverAuthId != viewer.authUserId) {
            await supabase.from('notifications').insert({
              'type': 'follow',
              'title': 'New follower',
              'message': '${viewer.username} started following you',
              'related_user_id': viewer.authUserId,
              'receiver_id': receiverAuthId,
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (_) {
          // notification is best-effort
        }

        state = const FollowState(isFollowing: true, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final followStateProvider = StateNotifierProvider.family<FollowNotifier,
    FollowState, ({String targetId, String targetType})>(
  (ref, args) => FollowNotifier(
    ref: ref,
    targetId: args.targetId,
    targetType: args.targetType,
  ),
);