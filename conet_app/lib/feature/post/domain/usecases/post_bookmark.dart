import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostBookmark {
  final PostRepository _postRepository;

  PostBookmark({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, Unit>> call(Post post) {
    return _postRepository.bookmarkPost(post);
  }
}
