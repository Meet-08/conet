import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source.dart';
import 'package:conet_app/feature/message/data/data_sources/message_real_time_datasource.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/entities/message_page.dart';
import 'package:conet_app/feature/message/domain/entities/message_realtime_event.dart';
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
  Future<Either<AppFailure, MessagePage>> getMessages(
    String conversationId, {
    int limit = 20,
    DateTime? before,
  }) {
    return _getResult(
      () => _messageDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
        before: before,
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
  Future<Either<AppFailure, Message>> sendMessage(
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
  Stream<MessageRealtimeEvent> watchMessages(String conversationId) {
    return _messageRealTimeDatasource.watchMessages(conversationId);
  }

  @override
  Stream<void> watchConversationUpdates() {
    return _messageRealTimeDatasource.watchConversationUpdates();
  }

  @override
  Future<Either<AppFailure, List<Conversation>>> getConversations({
    String type = 'all',
    String? search,
  }) {
    return _getResult(() {
      final normalizedSearch = search?.trim();
      if (normalizedSearch == null || normalizedSearch.isEmpty) {
        return _messageDataSource.getConversations(type: type);
      }

      return _messageDataSource.getConversations(
        type: type,
        search: normalizedSearch,
      );
    });
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

  // ─── Group operations ───────────────────────────────────────────────────────

  @override
  Future<Either<AppFailure, Conversation>> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    bool onlyAdminAddMembers = true,
    bool onlyAdminRemoveMembers = true,
    bool onlyAdminEditGroup = true,
    bool onlyAdminSendMessages = true,
    PlatformFile? groupImageFile,
  }) {
    return _getResult(() async {
      String? uploadedImageUrl;

      if (groupImageFile != null) {
        final urls = await _fileUploadDataSource.uploadFiles(
          files: [groupImageFile],
          bucket: 'message',
          folder: 'groups/$name',
        );
        if (urls.isNotEmpty) {
          uploadedImageUrl = urls.first;
        }
      }

      return _messageDataSource.createGroup(
        name: name,
        memberIds: memberIds,
        description: description,
        groupImageUrl: uploadedImageUrl,
        onlyAdminAddMembers: onlyAdminAddMembers,
        onlyAdminRemoveMembers: onlyAdminRemoveMembers,
        onlyAdminEditGroup: onlyAdminEditGroup,
        onlyAdminSendMessages: onlyAdminSendMessages,
      );
    });
  }

  @override
  Future<Either<AppFailure, Conversation>> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? groupImageUrl,
    bool? onlyAdminAddMembers,
    bool? onlyAdminRemoveMembers,
    bool? onlyAdminEditGroup,
    bool? onlyAdminSendMessages,
    PlatformFile? groupImageFile,
  }) {
    return _getResult(() async {
      var uploadedImageUrl = groupImageUrl;

      if (groupImageFile != null) {
        final urls = await _fileUploadDataSource.uploadFiles(
          files: [groupImageFile],
          bucket: 'message',
          folder: 'groups/$groupId',
        );
        if (urls.isNotEmpty) {
          uploadedImageUrl = urls.first;
        }
      }

      return _messageDataSource.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        groupImageUrl: uploadedImageUrl,
        onlyAdminAddMembers: onlyAdminAddMembers,
        onlyAdminRemoveMembers: onlyAdminRemoveMembers,
        onlyAdminEditGroup: onlyAdminEditGroup,
        onlyAdminSendMessages: onlyAdminSendMessages,
      );
    });
  }

  @override
  Future<Either<AppFailure, Unit>> deleteGroup(String groupId) {
    return _getResult(() => _messageDataSource.deleteGroup(groupId: groupId));
  }

  @override
  Future<Either<AppFailure, List<GroupMember>>> getGroupMembers(
    String groupId,
  ) {
    return _getResult(
      () => _messageDataSource.getGroupMembers(groupId: groupId),
    );
  }

  @override
  Future<Either<AppFailure, GroupMember>> addGroupMember({
    required String groupId,
    required String userId,
  }) {
    return _getResult(
      () => _messageDataSource.addGroupMember(groupId: groupId, userId: userId),
    );
  }

  @override
  Future<Either<AppFailure, Unit>> removeGroupMember({
    required String groupId,
    required String userId,
  }) {
    return _getResult(
      () => _messageDataSource.removeGroupMember(
        groupId: groupId,
        userId: userId,
      ),
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
