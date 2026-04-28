import 'package:json_annotation/json_annotation.dart';

part 'PostModel.g.dart';

@JsonSerializable()
class PostModel {
  final String id;
  final String authorId;
  final String? authorName;
  final String? authorImage;
  final String content;
  final List<String>? images;
  final String postType;
  final List<String> tags;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorImage,
    required this.content,
    this.images = const [],
    required this.postType,
    this.tags = const [],
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);
}