import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/Models/NotificationModel.dart';

/// Loads the user's notifications from the `notifications_feed` view.
/// Each row already includes the related user's name/avatar + role
/// and the related post's kind — so the screen needs zero extra queries.
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final supabase = Supabase.instance.client;

  final currentAuthId = supabase.auth.currentUser?.id;
  if (currentAuthId == null) return [];

  // ONE query — RLS still filters by receiver_id automatically.
  final data = await supabase
      .from('notifications_feed')
      .select()
      .order('created_at', ascending: false);

  return (data as List).map<NotificationModel>((row) {
    return NotificationModel(
      id: row['id'].toString(),
      type: row['type']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      message: row['message']?.toString() ?? '',
      relatedUserId: row['related_user_id']?.toString(),
      relatedPostId: row['related_post_id']?.toString(),
      isRead: row['is_read'] ?? false,
      createdAt: DateTime.parse(row['created_at'].toString()),

      // Enriched view fields
      relatedUserAppId: row['related_user_app_id']?.toString(),
      relatedUserType: row['related_user_type']?.toString(),
      relatedUserName: row['related_user_name']?.toString(),
      relatedUserImage: row['related_user_image']?.toString(),
      relatedPostKind: row['related_post_kind']?.toString(),
      relatedPostContent: row['related_post_content']?.toString(),
    );
  }).toList();
});

/// Lightweight server-side count for the bell badge.
/// Doesn't transfer any notification rows — just an integer.
final unreadNotificationsProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final supabase = Supabase.instance.client;
  final authId = supabase.auth.currentUser?.id;
  if (authId == null) return 0;

  // Server-side count(*). Replaces the old "fetch all rows then count" pattern.
  final response = await supabase
      .from('notifications')
      .count(CountOption.exact)
      .eq('receiver_id', authId)
      .eq('is_read', false);

  return response;
});