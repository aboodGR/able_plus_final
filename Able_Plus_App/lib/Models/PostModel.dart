import 'package:json_annotation/json_annotation.dart';

part 'PostModel.g.dart';

@JsonSerializable()
class PostModel {
  final String id;
  
  @JsonKey(name: 'author_id')
  final String authorId;
  
  @JsonKey(name: 'author_name')
  final String? authorName;
  
  @JsonKey(name: 'author_image')
  final String? authorImage;
  
  final String content;
  final List<String>? images;
  
  @JsonKey(name: 'video_url')
  final String? videoUrl;

  @JsonKey(name: 'donation_link')
  final String? donationLink;
  
  @JsonKey(name: 'post_type')
  final String postType;
  
  final List<String> tags;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  final int likes;
  final int comments;
  
  @JsonKey(name: 'is_liked')
  final bool isLiked;

  @JsonKey(name: 'is_vip')
  final bool isVip;

  @JsonKey(name: 'vip_expires_at')
  final DateTime? vipExpiresAt;

  PostModel({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorImage,
    required this.content,
    this.images = const [],
    this.videoUrl,
    this.donationLink,
    required this.postType,
    this.tags = const [],
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isVip = false,
    this.vipExpiresAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);
}