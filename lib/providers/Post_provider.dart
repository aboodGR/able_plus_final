import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ableplusproject/Models/PostModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final postsProvider = FutureProvider<List<PostModel>>((ref) async {
  final supabase = Supabase.instance.client;

  final data = await supabase
      .from('posts')
      .select()
      .order('id', ascending: false);

  return data.map<PostModel>((row) {
    return PostModel(
      id: row['id'].toString(),

     
      authorId: row['client_id'] ??
          row['tutor_id'] ??
          row['business_id'] ??
          row['charity_id'] ??
          '',

      authorName: 'User', 
      authorImage: null, 

      content: row['content'] ?? '',

      images: [], 

      postType: 'text', 

      tags: [],

      createdAt: DateTime.now(), 

      likes: row['likes'] ?? 0,
      comments: row['comments'] ?? 0,

      isLiked: false,
    );
  }).toList();
});