import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/shared_media_item.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class FetchSharedContent {
  final MessageRepository _repository;

  FetchSharedContent(this._repository);

  Future<Either<AppFailure, List<SharedMediaItem>>> call({
    required String conversationId,
    required SharedContentType type,
  }) {
    return _repository.getSharedContent(
      conversationId: conversationId,
      type: type,
    );
  }
}
