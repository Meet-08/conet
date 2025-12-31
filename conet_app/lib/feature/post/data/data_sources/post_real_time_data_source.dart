import 'package:conet_app/feature/post/domain/entities/post.dart';

abstract class PostRealtimeDataSource {
  Stream<List<Post>> watchPosts();
  Stream<Post> watchPost(String postId);
}
