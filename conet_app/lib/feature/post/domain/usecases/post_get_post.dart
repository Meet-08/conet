import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostGetPost {
  final PostRepository _postRepository;

  PostGetPost({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, Post>> call(String postId) {
    return _postRepository.getPost(postId);
  }
}
