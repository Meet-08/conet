import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';

class PostWatchPosts {
  final PostRepository _postRepository;

  PostWatchPosts({required PostRepository postRepository})
    : _postRepository = postRepository;

  Stream<List<Post>> call() {
    return _postRepository.watchPosts();
  }
}
