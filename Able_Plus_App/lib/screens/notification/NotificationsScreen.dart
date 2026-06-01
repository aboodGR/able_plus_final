import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/screens/Post/PostDetailsScreen.dart';
import 'package:ableplusproject/Models/NotificationModel.dart';
import 'package:ableplusproject/providers/notificationsProvider.dart';
import 'package:ableplusproject/screens/usertouser/FindAndSharePostDetails.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _formatTime(AppLocalizations l10n, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return l10n.justNow;
    if (difference.inMinutes < 60) return l10n.minutesAgo(difference.inMinutes);
    if (difference.inHours < 24) return l10n.hoursAgo(difference.inHours);
    if (difference.inDays < 7) return l10n.daysAgo(difference.inDays);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// The bold first line: the actor's name (UGC), or a localized fallback.
  String _titleFor(AppLocalizations l10n, NotificationModel item) {
    final name = item.relatedUserName;
    if (name != null && name.isNotEmpty) return name;
    return l10n.someone;
  }

  /// The action line, composed client-side from the type (name lives in title).
  String _messageFor(AppLocalizations l10n, NotificationModel item) {
    switch (item.type) {
      case 'like':
        return l10n.notifActionLiked;
      case 'comment':
        return l10n.notifActionCommented;
      case 'follow':
        return l10n.notifActionFollowed;
      case 'message':
        return l10n.notifActionMessaged;
      case 'booking':
        return l10n.notifActionBooking;
      default:
        return item.message;
    }
  }

  /// Full spoken text for TTS: name + action + post content (if any) + time.
  String _spokenTextFor(AppLocalizations l10n, NotificationModel item) {
    final parts = <String>[
      _titleFor(l10n, item),
      _messageFor(l10n, item),
    ];
    final content = item.relatedPostContent ?? '';
    if (content.isNotEmpty) parts.add(content);
    parts.add(_formatTime(l10n, item.createdAt));
    return parts.join('. ');
  }

  Future<void> _markAsRead(WidgetRef ref, String notificationId) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);

    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> _markAllAsRead(WidgetRef ref) async {
    final supabase = Supabase.instance.client;
    final currentAuthId = supabase.auth.currentUser?.id;
    if (currentAuthId == null) return;

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', currentAuthId)
        .eq('is_read', false);

    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  /// Now ZERO queries — everything we need is already in the model
  /// thanks to the notifications_feed view.
  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!item.isRead) {
      await _markAsRead(ref, item.id);
    }

    if (!context.mounted) return;

    final postId = item.relatedPostId;

    switch (item.type) {
      case 'like':
      case 'comment':
        if (postId == null || postId.isEmpty) return;

        // Use the pre-resolved kind from the view — no extra query.
        switch (item.relatedPostKind) {
          case 'community_post':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FindAndSharePostDetailsScreen(postId: postId),
              ),
            );
            return;
          case 'post':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailsScreen(postId: postId),
              ),
            );
            return;
          default:
            // Post was deleted.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.postNoLongerAvailableNotif),
              ),
            );
        }
        return;

      case 'follow':
        // The view gives us role + app_users.id directly — no extra query.
        final role = item.relatedUserType;
        final appId = item.relatedUserAppId;
        if (role != null && appId != null && appId.isNotEmpty) {
          context.push('/profile/$role/$appId');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userProfileNotAvailable)),
        );
        return;

      case 'message':
        context.push('/home/messages');
        return;

      case 'booking':
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider);

    return AbleScaffold(
      title: l10n.notifications,
      currentIndex: 0,
      actions: [
        TtsWrapper(
          text: l10n.markAllRead,
          child: TextButton(
            onPressed: () => _markAllAsRead(ref),
            child: Text(l10n.markAllRead, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationsProvider);
        },
        child: notificationsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 70,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noNotificationsYet,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final hasAvatar = (item.relatedUserImage ?? '').isNotEmpty;

                return TtsWrapper(
                  text: _spokenTextFor(l10n, item),
                  child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: item.isRead
                          ? Colors.grey.shade200
                          : Colors.blue.shade100,
                    ),
                  ),
                  color: item.isRead
                      ? null
                      : Colors.blue.shade50.withOpacity(0.4),
                  child: ListTile(
                    onTap: () => _handleTap(context, ref, item),
                    contentPadding: const EdgeInsets.all(14),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Real user avatar if we have one, otherwise fall
                        // back to the colored type-icon bubble.
                        if (hasAvatar)
                          CircleAvatar(
                            radius: 22,
                            backgroundImage:
                                NetworkImage(item.relatedUserImage!),
                          )
                        else
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _backgroundColorFor(item.type),
                            child: Icon(
                              _iconFor(item.type),
                              color: _iconColorFor(item.type),
                            ),
                          ),
                        // Small type indicator pinned to the corner
                        PositionedDirectional(
                          end: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Icon(
                              _iconFor(item.type),
                              size: 12,
                              color: _iconColorFor(item.type),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      _titleFor(l10n, item),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _messageFor(l10n, item),
                            style: const TextStyle(height: 1.3),
                          ),
                        ),
                        if ((item.relatedPostContent ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '"${item.relatedPostContent}"',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatTime(l10n, item.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: item.isRead
                        ? null
                        : const Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.blue,
                          ),
                  ),
                ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              '${l10n.error}: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_border_rounded;
      case 'comment':
        return Icons.mode_comment_outlined;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'booking':
        return Icons.calendar_today_outlined;
      case 'follow':
        return Icons.person_add_alt_1_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _backgroundColorFor(String type) {
    switch (type) {
      case 'like':
        return Colors.red.shade50;
      case 'comment':
        return Colors.orange.shade50;
      case 'message':
        return Colors.blue.shade50;
      case 'booking':
        return Colors.green.shade50;
      case 'follow':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _iconColorFor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.orange;
      case 'message':
        return Colors.blue;
      case 'booking':
        return Colors.green;
      case 'follow':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}