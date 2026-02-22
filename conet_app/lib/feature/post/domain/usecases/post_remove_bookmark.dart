import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostRemoveBookmark {
  final PostRepository _postRepository;

  PostRemoveBookmark({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, Unit>> call(String postId) {
    return _postRepository.removeBookmark(postId);
  }
}
