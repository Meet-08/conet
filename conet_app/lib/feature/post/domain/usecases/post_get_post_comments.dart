import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostGetPostComments {
  final PostRepository _postRepository;

  PostGetPostComments({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, List<Comment>>> call(String postId) {
    return _postRepository.getPostComments(postId);
  }
}
