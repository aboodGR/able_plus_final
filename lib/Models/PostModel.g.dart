
part of 'PostModel.dart';

PostModel _$PostModelFromJson(Map<String, dynamic> json) => PostModel(
  id: json['id'] as String,
  authorId: json['authorId'] as String,
  authorName: json['authorName'] as String?,
  authorImage: json['authorImage'] as String?,
  content: json['content'] as String,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  postType: json['postType'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  comments: (json['comments'] as num?)?.toInt() ?? 0,
  isLiked: json['isLiked'] as bool? ?? false,
);

Map<String, dynamic> _$PostModelToJson(PostModel instance) => <String, dynamic>{
  'id': instance.id,
  'authorId': instance.authorId,
  'authorName': instance.authorName,
  'authorImage': instance.authorImage,
  'content': instance.content,
  'images': instance.images,
  'postType': instance.postType,
  'tags': instance.tags,
  'createdAt': instance.createdAt.toIso8601String(),
  'likes': instance.likes,
  'comments': instance.comments,
  'isLiked': instance.isLiked,
};
