import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostDelete {
  final PostRepository _postRepository;

  PostDelete({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, Unit>> call(String postId) {
    return _postRepository.deletePost(postId);
  }
}
