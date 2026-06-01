import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';

class FindAndSharePost {
  final String id;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final String userTag;
  final DateTime createdAt;
  final String? userId;
  final String? avatarUrl;

  FindAndSharePost({
    required this.id,
    required this.description,
    required this.imageUrl,
    required this.videoUrl,
    required this.userTag,
    required this.createdAt,
    required this.userId,
    required this.avatarUrl,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
}

class FindAndShareScreen extends StatefulWidget {
  const FindAndShareScreen({super.key});

  @override
  State<FindAndShareScreen> createState() => _FindAndShareScreenState();
}

class _FindAndShareScreenState extends State<FindAndShareScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<List<FindAndSharePost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<FindAndSharePost>> _fetchPosts() async {
    final rawPosts = await _supabase
        .from('community_posts')
        .select('id, description, image_url, video_url, '
            'created_at, user_id, account_id, account_type')
        .order('created_at', ascending: false);

    final posts = List<Map<String, dynamic>>.from(rawPosts);
    if (posts.isEmpty) return [];

    final accountIds = <String>{};
    for (final p in posts) {
      final id = p['account_id']?.toString();
      if (id != null && id.isNotEmpty) accountIds.add(id);
    }

    final authorMap = <String, Map<String, dynamic>>{};
    if (accountIds.isNotEmpty) {
      final authors = await _supabase
          .from('app_users')
          .select('id, account_type, display_name, profile_pic_url')
          .inFilter('id', accountIds.toList());

      for (final a in authors as List) {
        final key = '${a['id']}:${a['account_type']}';
        authorMap[key] = Map<String, dynamic>.from(a as Map);
      }
    }

    return posts.map((p) {
      final accountId = p['account_id']?.toString();
      final accountTypeRaw = p['account_type']?.toString() ?? '';
      final accountTypeSingular = _normalizeAccountType(accountTypeRaw);
      final key = '$accountId:$accountTypeSingular';
      final author = authorMap[key];

      return FindAndSharePost(
        id: p['id'].toString(),
        description: p['description']?.toString() ?? '',
        imageUrl: p['image_url']?.toString(),
        videoUrl: p['video_url']?.toString(),
        userTag: author?['display_name']?.toString() ?? 'User',
        createdAt: DateTime.parse(p['created_at'].toString()),
        userId: p['user_id']?.toString(),
        avatarUrl: author?['profile_pic_url']?.toString(),
      );
    }).toList();
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

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _fetchPosts();
    });
    await _postsFuture;
  }

  Widget _buildProfileAvatar(FindAndSharePost post) {
    if (post.hasAvatar) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xff4a90e2),
        backgroundImage: NetworkImage(post.avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return const CircleAvatar(
      radius: 24,
      backgroundColor: Color(0xff4a90e2),
      child: Icon(Icons.person_outline, color: Colors.white),
    );
  }

  Widget _buildPostThumbnail(FindAndSharePost post) {
    const double size = 92;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        post.imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Colors.black12,
          child: const Icon(Icons.broken_image_outlined, color: Colors.black38),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AbleScaffold(
      title: l10n.findAndShare,
      showBackButton: true,
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<FindAndSharePost>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    l10n.somethingWentWrong,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            final posts = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                // ── العنوان والـ subtitle في الوسط ── ← التعديل
                TtsWrapper(
                  text: l10n.findAndShare,
                  child: Text(
                    l10n.findAndShare,
                    textAlign: TextAlign.center, // ← التعديل
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff33496d),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TtsWrapper(
                  text: l10n.findAndShareSubtitle,
                  child: Text(
                    l10n.findAndShareSubtitle,
                    textAlign: TextAlign.center, // ← التعديل
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xff33496d)),
                  ),
                ),
                const SizedBox(height: 18),
                if (posts.isEmpty)
                  TtsWrapper(
                    text: '${l10n.noPostsYet}. ${l10n.noPostsShareHint}',
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 48, color: Color(0xff4a90e2)),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noPostsYet,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff33496d),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noPostsShareHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xff33496d)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...posts.map((post) {
                  final isAr = l10n.localeName == 'ar';
                  final spokenParts = <String>[
                    post.userTag,
                    if (post.hasVideo) (isAr ? 'فيديو' : 'Video'),
                    if (post.description.trim().isNotEmpty) post.description,
                  ];
                  final spokenText =
                      spokenParts.where((p) => p.trim().isNotEmpty).join('. ');

                  return TtsWrapper(
                    text: spokenText,
                    child: GestureDetector(
                     onTap: () {
                        context.go('/home/Findandshare/post/${post.id}');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.75),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileAvatar(post),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF7FC),
                                          borderRadius:
                                              BorderRadius.circular(22),
                                        ),
                                        child: Text(
                                          post.userTag,
                                          style: const TextStyle(
                                            color: Color(0xff2f72b8),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (post.hasVideo)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 9, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.black
                                                  .withOpacity(0.15),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.play_circle_fill_rounded,
                                                size: 14,
                                                color: Colors.black87,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.videoBadge,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    post.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.4,
                                      color: Color(0xff33496d),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (post.hasImage) ...[
                              const SizedBox(width: 10),
                              _buildPostThumbnail(post),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}