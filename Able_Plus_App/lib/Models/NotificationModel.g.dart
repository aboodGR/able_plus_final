// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'NotificationModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      relatedUserId: json['related_user_id'] as String?,
      relatedPostId: json['related_post_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      relatedUserAppId: json['related_user_app_id'] as String?,
      relatedUserType: json['related_user_type'] as String?,
      relatedUserName: json['related_user_name'] as String?,
      relatedUserImage: json['related_user_image'] as String?,
      relatedPostKind: json['related_post_kind'] as String?,
      relatedPostContent: json['related_post_content'] as String?,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'message': instance.message,
      'related_user_id': instance.relatedUserId,
      'related_post_id': instance.relatedPostId,
      'created_at': instance.createdAt.toIso8601String(),
      'is_read': instance.isRead,
      'related_user_app_id': instance.relatedUserAppId,
      'related_user_type': instance.relatedUserType,
      'related_user_name': instance.relatedUserName,
      'related_user_image': instance.relatedUserImage,
      'related_post_kind': instance.relatedPostKind,
      'related_post_content': instance.relatedPostContent,
    };
