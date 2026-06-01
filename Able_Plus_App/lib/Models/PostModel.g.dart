// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PostModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostModel _$PostModelFromJson(Map<String, dynamic> json) => PostModel(
  id: json['id'] as String,
  authorId: json['author_id'] as String,
  authorName: json['author_name'] as String?,
  authorImage: json['author_image'] as String?,
  content: json['content'] as String,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  videoUrl: json['video_url'] as String?,
  donationLink: json['donation_link'] as String?,
  postType: json['post_type'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  comments: (json['comments'] as num?)?.toInt() ?? 0,
  isLiked: json['is_liked'] as bool? ?? false,
  isVip: json['is_vip'] as bool? ?? false,
  vipExpiresAt: json['vip_expires_at'] == null
      ? null
      : DateTime.parse(json['vip_expires_at'] as String),
);

Map<String, dynamic> _$PostModelToJson(PostModel instance) => <String, dynamic>{
  'id': instance.id,
  'author_id': instance.authorId,
  'author_name': instance.authorName,
  'author_image': instance.authorImage,
  'content': instance.content,
  'images': instance.images,
  'video_url': instance.videoUrl,
  'donation_link': instance.donationLink,
  'post_type': instance.postType,
  'tags': instance.tags,
  'created_at': instance.createdAt.toIso8601String(),
  'likes': instance.likes,
  'comments': instance.comments,
  'is_liked': instance.isLiked,
  'is_vip': instance.isVip,
  'vip_expires_at': instance.vipExpiresAt?.toIso8601String(),
};
