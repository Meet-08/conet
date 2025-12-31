import 'dart:async';

import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/post/data/data_sources/post_real_time_data_source.dart';
import 'package:conet_app/feature/post/data/models/post_model.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class SupabasePostRealTimeDatasourceImpl implements PostRealtimeDataSource {
  final SupabaseClient supabaseClient;

  SupabasePostRealTimeDatasourceImpl({required this.supabaseClient});

  @override
  Stream<Post> watchPost(String postId) {
    return supabaseClient
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('id', postId)
        .asyncMap((rows) async {
          if (rows.isEmpty) {
            throw Exception('Post not found');
          }
          return await _parsePostWithUser(rows.first);
        });
  }

  @override
  Stream<List<Post>> watchPosts() {
    return supabaseClient
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
          logger.i('Realtime: Received ${rows.length} posts update');
          final posts = await Future.wait(
            rows.map((row) => _parsePostWithUser(row)),
          );
          return posts;
        });
  }

  Future<PostModel> _parsePostWithUser(Map<String, dynamic> postData) async {
    final currentUserId = supabaseClient.auth.currentUser?.id;

    User user;
    try {
      final userData = await supabaseClient
          .from('users')
          .select()
          .eq('id', postData['user_id'])
          .single();
      user = User.fromJson(userData);
    } catch (e) {
      logger.w('Failed to fetch user for post: ${postData['id']}');
      user = User(
        id: postData['user_id'] ?? '',
        email: '',
        firstName: '',
        lastName: '',
        username: 'Unknown',
        profilePicUrl: '',
        userRole: UserRole.user,
      );
    }

    bool isLiked = false;
    if (currentUserId != null) {
      final likeCheck = await supabaseClient
          .from('post_likes')
          .select()
          .eq('post_id', postData['id'])
          .eq('user_id', currentUserId)
          .maybeSingle();
      isLiked = likeCheck != null;
    }

    return PostModel(
      id: postData['id'],
      user: user,
      content: postData['content'] ?? '',
      mediaUrls: List<String>.from(postData['media_urls'] ?? []),
      likeCount: postData['like_count'] ?? 0,
      commentCount: postData['comment_count'] ?? 0,
      isLiked: isLiked,
      createdAt: DateTime.parse(
        postData['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
