import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';

class PostWatchPostComments {
  final PostRepository _postRepository;

  PostWatchPostComments({required PostRepository postRepository})
    : _postRepository = postRepository;

  Stream<List<Comment>> call(String postId) {
    return _postRepository.watchPostComments(postId);
  }
}
