import 'dart:async';

import 'package:conet_app/feature/post/data/data_sources/post_real_time_data_source.dart';
import 'package:conet_app/feature/post/data/models/post_model.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class SupabasePostRealTimeDatasourceImpl implements PostRealtimeDataSource {
  final SupabaseClient supabaseClient;

  SupabasePostRealTimeDatasourceImpl({required this.supabaseClient});

  @override
  Stream<Post> watchPost(String postId) {
    return supabaseClient
        .from('posts_with_meta')
        .stream(primaryKey: ['id'])
        .eq('id', postId)
        .map((rows) => PostModel.fromJson(rows.first));
  }

  @override
  Stream<List<Post>> watchPosts() {
    return supabaseClient
        .from('posts_with_meta')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((e) => PostModel.fromJson(e)).toList());
  }
}
