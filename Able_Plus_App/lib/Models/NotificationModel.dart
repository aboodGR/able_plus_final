import 'package:json_annotation/json_annotation.dart';

part 'NotificationModel.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? relatedUserId;
  final String? relatedPostId;
  final DateTime createdAt;
  final bool isRead;

  // ─── Enriched fields from notifications_feed view ───
  final String? relatedUserAppId;      // app_users.id of the triggerer
  final String? relatedUserType;       // 'client' | 'tutor' | 'business' | 'charity'
  final String? relatedUserName;       // display name
  final String? relatedUserImage;      // profile pic URL
  final String? relatedPostKind;       // 'post' | 'community_post' | null
  final String? relatedPostContent;    // short preview, may be null

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.relatedUserId,
    this.relatedPostId,
    required this.createdAt,
    this.isRead = false,
    this.relatedUserAppId,
    this.relatedUserType,
    this.relatedUserName,
    this.relatedUserImage,
    this.relatedPostKind,
    this.relatedPostContent,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}