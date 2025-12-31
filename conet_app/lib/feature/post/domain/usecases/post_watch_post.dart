import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';

class PostWatchPost {
  final PostRepository _postRepository;

  PostWatchPost({required PostRepository postRepository})
    : _postRepository = postRepository;

  Stream<Post> call(String postId) {
    return _postRepository.watchPost(postId);
  }
}
