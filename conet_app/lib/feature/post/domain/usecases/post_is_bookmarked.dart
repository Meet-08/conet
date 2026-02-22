import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostIsBookmarked {
  final PostRepository _postRepository;

  PostIsBookmarked({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, bool>> call(String postId) {
    return _postRepository.isPostBookmarked(postId);
  }
}
