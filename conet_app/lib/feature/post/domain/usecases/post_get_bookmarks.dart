import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostGetBookmarks {
  final PostRepository _postRepository;

  PostGetBookmarks({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, List<Post>>> call() {
    return _postRepository.getBookmarkedPosts();
  }
}
