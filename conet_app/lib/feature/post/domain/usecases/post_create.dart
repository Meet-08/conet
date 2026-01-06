import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

class PostCreate {
  final PostRepository _postRepository;

  PostCreate({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, Post>> call({
    required String content,
    required List<PlatformFile> media,
  }) async {
    return await _postRepository.createPost(content: content, media: media);
  }
}
