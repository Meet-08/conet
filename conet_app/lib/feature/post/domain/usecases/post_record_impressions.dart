import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostRecordImpressions {
  final PostRepository _postRepository;

  PostRecordImpressions({required PostRepository postRepository})
      : _postRepository = postRepository;

  Future<Either<AppFailure, Unit>> call(List<String> postIds) {
    return _postRepository.recordImpressions(postIds);
  }
}
