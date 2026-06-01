import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/screens/Post/PostDetailsScreen.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';

class _ActivityItem {
  final String type;
  final DateTime createdAt;
  final String? postId;
  final String? commentPreview;
  final String? targetName;
  final String? targetUserId;
  final String? targetRole;

  const _ActivityItem({
    required this.type,
    required this.createdAt,
    this.postId,
    this.commentPreview,
    this.targetName,
    this.targetUserId,
    this.targetRole,
  });
}

final myActivityProvider =
    FutureProvider.autoDispose<List<_ActivityItem>>((ref) async {
  final supabase = Supabase.instance.client;
  final email = supabase.auth.currentUser?.email?.toLowerCase();
  if (email == null || email.isEmpty) return [];

  String? viewerId;
  String? viewerRole;
  String? viewerIdColumn;

  const roleSearches = [
    ('clients', 'client', 'client_id'),
    ('tutors', 'tutor', 'tutor_id'),
    ('businesses', 'business', 'business_id'),
    ('charities', 'charity', 'charity_id'),
  ];

  for (final entry in roleSearches) {
    final row = await supabase
        .from(entry.$1)
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (row != null) {
      viewerId = row['id'].toString();
      viewerRole = entry.$2;
      viewerIdColumn = entry.$3;
      break;
    }
  }

  if (viewerId == null || viewerRole == null || viewerIdColumn == null) {
    return [];
  }

  final items = <_ActivityItem>[];

  try {
    final likes = await supabase
        .from('post_likes')
        .select('id, post_id, created_at')
        .eq(viewerIdColumn, viewerId)
        .order('created_at', ascending: false)
        .limit(50);
    for (final row in likes) {
      final createdRaw = row['created_at']?.toString();
      if (createdRaw == null) continue;
      items.add(_ActivityItem(
        type: 'like',
        createdAt: DateTime.parse(createdRaw),
        postId: row['post_id']?.toString(),
      ));
    }
  } catch (_) {}

  try {
    final comments = await supabase
        .from('post_comments')
        .select('id, post_id, comment_text, created_at')
        .eq(viewerIdColumn, viewerId)
        .order('created_at', ascending: false)
        .limit(50);
    for (final row in comments) {
      final createdRaw = row['created_at']?.toString();
      if (createdRaw == null) continue;
      final commentText = row['comment_text']?.toString() ?? '';
      final preview = commentText.length > 80
          ? '${commentText.substring(0, 80)}…'
          : commentText;
      items.add(_ActivityItem(
        type: 'comment',
        createdAt: DateTime.parse(createdRaw),
        postId: row['post_id']?.toString(),
        commentPreview: preview,
      ));
    }
  } catch (_) {}

  try {
    final saved = await supabase
        .from('saved_posts')
        .select('id, post_id, created_at')
        .eq(viewerIdColumn, viewerId)
        .order('created_at', ascending: false)
        .limit(50);
    for (final row in saved) {
      final createdRaw = row['created_at']?.toString();
      if (createdRaw == null) continue;
      items.add(_ActivityItem(
        type: 'save',
        createdAt: DateTime.parse(createdRaw),
        postId: row['post_id']?.toString(),
      ));
    }
  } catch (_) {}

  if (viewerRole == 'client') {
    try {
      final follows = await supabase
          .from('follows')
          .select(
            'followed_client_id, followed_tutor_id, followed_business_id, '
            'followed_charity_id, created_at',
          )
          .eq('follower_client_id', viewerId)
          .order('created_at', ascending: false)
          .limit(50);

      for (final row in follows) {
        final createdRaw = row['created_at']?.toString();
        if (createdRaw == null) continue;

        String targetTable = '';
        String targetId = '';
        String targetRole = '';

        if (row['followed_client_id'] != null) {
          targetTable = 'clients';
          targetId = row['followed_client_id'].toString();
          targetRole = 'client';
        } else if (row['followed_tutor_id'] != null) {
          targetTable = 'tutors';
          targetId = row['followed_tutor_id'].toString();
          targetRole = 'tutor';
        } else if (row['followed_business_id'] != null) {
          targetTable = 'businesses';
          targetId = row['followed_business_id'].toString();
          targetRole = 'business';
        } else if (row['followed_charity_id'] != null) {
          targetTable = 'charities';
          targetId = row['followed_charity_id'].toString();
          targetRole = 'charity';
        }

        String? targetName;
        if (targetTable.isNotEmpty && targetId.isNotEmpty) {
          try {
            final profile = await supabase
                .from(targetTable)
                .select('username')
                .eq('id', targetId)
                .maybeSingle();
            final username = profile?['username']?.toString();
            if (username != null && username.isNotEmpty) {
              targetName = username;
            }
          } catch (_) {}
        }

        items.add(_ActivityItem(
          type: 'follow',
          createdAt: DateTime.parse(createdRaw),
          targetName: targetName,
          targetUserId: targetId.isEmpty ? null : targetId,
          targetRole: targetRole.isEmpty ? null : targetRole,
        ));
      }
    } catch (_) {}
  }

  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
});

String _formatTime(AppLocalizations l10n, DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inSeconds < 60) return l10n.justNow;
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

String _titleFor(AppLocalizations l10n, _ActivityItem item) {
  switch (item.type) {
    case 'like':
      return l10n.youLikedAPost;
    case 'comment':
      return l10n.youCommentedOnAPost;
    case 'save':
      return l10n.youSavedAPost;
    case 'follow':
      return l10n.youFollowed(item.targetName ?? l10n.someone);
    default:
      return '';
  }
}

String _subtitleFor(AppLocalizations l10n, _ActivityItem item) {
  switch (item.type) {
    case 'comment':
      final preview = item.commentPreview ?? '';
      return preview.isEmpty ? l10n.tapToViewPost : '"$preview"';
    case 'like':
    case 'save':
      return l10n.tapToViewPost;
    case 'follow':
      return (item.targetUserId != null && item.targetUserId!.isNotEmpty)
          ? l10n.tapToOpenProfile
          : '';
    default:
      return '';
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'like':
      return Icons.favorite_rounded;
    case 'comment':
      return Icons.mode_comment_outlined;
    case 'follow':
      return Icons.person_add_alt_1_rounded;
    case 'save':
      return Icons.bookmark_rounded;
    default:
      return Icons.circle_outlined;
  }
}

Color _bgFor(String type) {
  switch (type) {
    case 'like':
      return Colors.red.shade50;
    case 'comment':
      return Colors.blue.shade50;
    case 'follow':
      return Colors.green.shade50;
    case 'save':
      return Colors.orange.shade50;
    default:
      return Colors.grey.shade100;
  }
}

Color _iconColorFor(String type) {
  switch (type) {
    case 'like':
      return Colors.red.shade400;
    case 'comment':
      return Colors.blue.shade400;
    case 'follow':
      return Colors.green.shade400;
    case 'save':
      return Colors.orange.shade400;
    default:
      return Colors.grey.shade400;
  }
}

class MyActivityScreen extends ConsumerStatefulWidget {
  const MyActivityScreen({super.key});

  @override
  ConsumerState<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends ConsumerState<MyActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onActivityTap(BuildContext context, _ActivityItem item) {
    final l10n = AppLocalizations.of(context)!;
    switch (item.type) {
      case 'like':
      case 'comment':
      case 'save':
        final postId = item.postId;
        if (postId == null || postId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.postNoLongerAvailable)),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(postId: postId),
          ),
        );
        return;

      case 'follow':
        final userId = item.targetUserId;
        final role = item.targetRole;
        if (userId != null &&
            userId.isNotEmpty &&
            role != null &&
            role.isNotEmpty) {
          context.push('/profile/$role/$userId');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileNotAvailable)),
        );
        return;

      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);
    final isDark = AbleTheme.isDark(context);
    final activityAsync = ref.watch(myActivityProvider);

    return AbleScaffold(
      title: l10n.myActivity,
      currentIndex: 0,
      showBackButton: true,
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.error_outline, size: 48, color: mutedColor),
            const SizedBox(height: 12),
            Text(
              l10n.couldNotLoadActivity,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
          ],
        ),
        data: (items) {
          final comments = items.where((i) => i.type == 'comment').toList();
          final likes = items.where((i) => i.type == 'like').toList();
          final saves = items.where((i) => i.type == 'save').toList();

          return Column(
            children: [
              // ── Tab bar ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2D40)
                      : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AbleTheme.glassBorder(context)),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: accentColor,
                  unselectedLabelColor: mutedColor,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    // ── كل تاب ملفوف بـ TtsWrapper ──
                    TtsWrapper(
                      text: '${l10n.comments}'
                          '${comments.isNotEmpty ? ", ${comments.length}" : ""}',
                      child: Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mode_comment_outlined, size: 16),
                            const SizedBox(width: 5),
                            Text(l10n.comments),
                            if (comments.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _Badge(count: comments.length),
                            ],
                          ],
                        ),
                      ),
                    ),
                    TtsWrapper(
                      text: '${l10n.likes}'
                          '${likes.isNotEmpty ? ", ${likes.length}" : ""}',
                      child: Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_rounded, size: 16),
                            const SizedBox(width: 5),
                            Text(l10n.likes),
                            if (likes.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _Badge(count: likes.length),
                            ],
                          ],
                        ),
                      ),
                    ),
                    TtsWrapper(
                      text: '${l10n.saved}'
                          '${saves.isNotEmpty ? ", ${saves.length}" : ""}',
                      child: Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bookmark_rounded, size: 16),
                            const SizedBox(width: 5),
                            Text(l10n.saved),
                            if (saves.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _Badge(count: saves.length),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab content ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ActivityList(
                      items: comments,
                      emptyMessage: l10n.noCommentsYet,
                      emptyIcon: Icons.mode_comment_outlined,
                      onTap: (item) => _onActivityTap(context, item),
                    ),
                    _ActivityList(
                      items: likes,
                      emptyMessage: l10n.noLikesYet,
                      emptyIcon: Icons.favorite_border_rounded,
                      onTap: (item) => _onActivityTap(context, item),
                    ),
                    _ActivityList(
                      items: saves,
                      emptyMessage: l10n.noSavedYet,
                      emptyIcon: Icons.bookmark_border_rounded,
                      onTap: (item) => _onActivityTap(context, item),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AbleTheme.accent(context).withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AbleTheme.accent(context),
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.items,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onTap,
  });

  final List<_ActivityItem> items;
  final String emptyMessage;
  final IconData emptyIcon;
  final void Function(_ActivityItem) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 56, color: mutedColor),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                color: mutedColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final bool canTap;
          if (item.type == 'like' ||
              item.type == 'comment' ||
              item.type == 'save') {
            canTap = item.postId != null && item.postId!.isNotEmpty;
          } else if (item.type == 'follow') {
            canTap = item.targetUserId != null &&
                item.targetUserId!.isNotEmpty &&
                item.targetRole != null &&
                item.targetRole!.isNotEmpty;
          } else {
            canTap = false;
          }

          final title = _titleFor(l10n, item);
          final subtitle = _subtitleFor(l10n, item);
          final timeStr = _formatTime(l10n, item.createdAt);

          // ── النص المقروء: العنوان + الـ subtitle + الوقت ──
          final ttsText = [
            title,
            if (subtitle.isNotEmpty) subtitle,
            timeStr,
          ].join('. ');

          return TtsWrapper(
            text: ttsText,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                onTap: canTap ? () => onTap(item) : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor: _bgFor(item.type),
                  child: Icon(
                    _iconFor(item.type),
                    color: _iconColorFor(item.type),
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: TextStyle(color: mutedColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: mutedColor),
                      ),
                    ),
                  ],
                ),
                trailing: canTap
                    ? Transform.flip(
                        flipX: isRtl,
                        child: Icon(Icons.chevron_right_rounded,
                            color: mutedColor),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}