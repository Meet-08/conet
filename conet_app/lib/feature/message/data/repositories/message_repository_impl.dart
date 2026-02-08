import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source.dart';
import 'package:conet_app/feature/message/data/data_sources/message_real_time_datasource.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageDataSource _messageDataSource;
  final MessageRealTimeDatasource _messageRealTimeDatasource;
  final FileUploadDataSource _fileUploadDataSource;

  MessageRepositoryImpl({
    required MessageDataSource messageDataSource,
    required MessageRealTimeDatasource messageRealTimeDatasource,
    required FileUploadDataSource fileUploadDataSource,
  }) : _messageDataSource = messageDataSource,
       _messageRealTimeDatasource = messageRealTimeDatasource,
       _fileUploadDataSource = fileUploadDataSource;

  @override
  Future<Either<AppFailure, Conversation>> createConversation(String userId) {
    return _getResult(
      () => _messageDataSource.createConversation(userId: userId),
    );
  }

  @override
  Future<Either<AppFailure, List<Message>>> getMessages(
    String conversationId, {
    int limit = 20,
  }) {
    return _getResult(
      () => _messageDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
      ),
    );
  }

  @override
  Future<Either<AppFailure, Unit>> markAsRead(String conversationId) {
    return _getResult(
      () => _messageDataSource.markAsRead(conversationId: conversationId),
    );
  }

  @override
  Future<Either<AppFailure, Unit>> sendMessage(
    String conversationId,
    String message, {
    List<String>? mediaUrls,
    List<PlatformFile>? files,
  }) async {
    return _getResult(() async {
      List<String>? uploadedUrls = mediaUrls;

      // If files are provided, upload them first to get URLs
      if (files != null && files.isNotEmpty) {
        final fileUrls = await _fileUploadDataSource.uploadFiles(
          files: files,
          bucket: 'message',
          folder: conversationId,
        );

        // Combine with any existing mediaUrls
        uploadedUrls = [...?uploadedUrls, ...fileUrls];
      }

      // Send message with the uploaded URLs
      return await _messageDataSource.sendMessage(
        conversationId: conversationId,
        content: message,
        mediaUrls: uploadedUrls,
      );
    });
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _messageRealTimeDatasource.watchMessages(conversationId);
  }

  @override
  Future<Either<AppFailure, List<Conversation>>> getConversations() {
    return _getResult(() => _messageDataSource.getConversations());
  }

  @override
  Future<Either<AppFailure, List<User>>> searchUsers(
    String query, {
    int limit = 3,
  }) {
    return _getResult(
      () => _messageDataSource.searchUsers(query: query, limit: limit),
    );
  }

  Future<Either<AppFailure, T>> _getResult<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
