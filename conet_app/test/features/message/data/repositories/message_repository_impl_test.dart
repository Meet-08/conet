import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source.dart';
import 'package:conet_app/feature/message/data/data_sources/message_real_time_datasource.dart';
import 'package:conet_app/feature/message/data/models/conversation_model.dart';
import 'package:conet_app/feature/message/data/models/message_model.dart';
import 'package:conet_app/feature/message/data/repositories/message_repository_impl.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageDataSource extends Mock implements MessageDataSource {}

class MockMessageRealTimeDatasource extends Mock
    implements MessageRealTimeDatasource {}

class MockFileUploadDataSource extends Mock implements FileUploadDataSource {}

void main() {
  late MessageRepositoryImpl repository;
  late MockMessageDataSource mockMessageDataSource;
  late MockMessageRealTimeDatasource mockMessageRealTimeDatasource;
  late MockFileUploadDataSource mockFileUploadDataSource;

  setUp(() {
    mockMessageDataSource = MockMessageDataSource();
    mockMessageRealTimeDatasource = MockMessageRealTimeDatasource();
    mockFileUploadDataSource = MockFileUploadDataSource();
    repository = MessageRepositoryImpl(
      messageDataSource: mockMessageDataSource,
      messageRealTimeDatasource: mockMessageRealTimeDatasource,
      fileUploadDataSource: mockFileUploadDataSource,
    );
  });

  const tUser = User(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
    isVerified: true,
  );

  const tConversationModel = ConversationModel(
    id: 'conversation-123',
    otherUser: tUser,
  );

  final tMessageModel = MessageModel(
    id: 'message-123',
    conversationId: 'conversation-123',
    senderId: 'user-123',
    content: 'Test message',
    createdAt: DateTime(2024, 1, 1),
  );

  final tConversationList = [tConversationModel];
  final tMessageList = [tMessageModel];
  final tUserList = [tUser];

  group('createConversation', () {
    const tUserId = 'user-123';

    test('should return Right<Conversation> on success', () async {
      when(
        () => mockMessageDataSource.createConversation(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => tConversationModel);

      final result = await repository.createConversation(tUserId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (conversation) => expect(conversation.id, tConversationModel.id),
      );
      verify(
        () => mockMessageDataSource.createConversation(userId: tUserId),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockMessageDataSource.createConversation(
          userId: any(named: 'userId'),
        ),
      ).thenThrow(ServerException('Failed to create conversation'));

      final result = await repository.createConversation(tUserId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to create conversation'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when generic exception is thrown', () async {
      when(
        () => mockMessageDataSource.createConversation(
          userId: any(named: 'userId'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      final result = await repository.createConversation(tUserId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message.contains('Exception'), true),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('sendMessage', () {
    const tConversationId = 'conversation-123';
    const tContent = 'Test message';

    test('should return Right<Message> on success', () async {
      when(
        () => mockMessageDataSource.sendMessage(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenAnswer((_) async => tMessageModel);

      final result = await repository.sendMessage(tConversationId, tContent);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (message) => expect(message.id, tMessageModel.id),
      );
      verify(
        () => mockMessageDataSource.sendMessage(
          conversationId: tConversationId,
          content: tContent,
          mediaUrls: null,
        ),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockMessageDataSource.sendMessage(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenThrow(ServerException('Failed to send message'));

      final result = await repository.sendMessage(tConversationId, tContent);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to send message'),
        (_) => fail('Expected Left'),
      );
    });

    test('should send message with media URLs successfully', () async {
      // arrange
      const tMediaUrls = [
        'https://example.com/image.jpg',
        'https://example.com/video.mp4',
      ];
      when(
        () => mockMessageDataSource.sendMessage(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenAnswer((_) async => tMessageModel);

      // act
      final result = await repository.sendMessage(
        tConversationId,
        tContent,
        mediaUrls: tMediaUrls,
      );

      // assert
      expect(result.isRight(), true);
      verify(
        () => mockMessageDataSource.sendMessage(
          conversationId: tConversationId,
          content: tContent,
          mediaUrls: tMediaUrls,
        ),
      ).called(1);
    });

    test('should pass null mediaUrls when not provided', () async {
      // arrange
      when(
        () => mockMessageDataSource.sendMessage(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenAnswer((_) async => tMessageModel);

      // act
      final result = await repository.sendMessage(tConversationId, tContent);

      // assert
      expect(result.isRight(), true);
      verify(
        () => mockMessageDataSource.sendMessage(
          conversationId: tConversationId,
          content: tContent,
          mediaUrls: null,
        ),
      ).called(1);
    });
  });

  group('getMessages', () {
    const tConversationId = 'conversation-123';

    test('should return Right<List<Message>> on success', () async {
      when(
        () => mockMessageDataSource.getMessages(
          conversationId: any(named: 'conversationId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tMessageList);

      final result = await repository.getMessages(tConversationId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (messages) => expect(messages.length, 1),
      );
      verify(
        () => mockMessageDataSource.getMessages(
          conversationId: tConversationId,
          limit: 20,
        ),
      ).called(1);
    });

    test('should return Right<List<Message>> with custom limit', () async {
      when(
        () => mockMessageDataSource.getMessages(
          conversationId: any(named: 'conversationId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tMessageList);

      final result = await repository.getMessages(tConversationId, limit: 50);

      expect(result.isRight(), true);
      verify(
        () => mockMessageDataSource.getMessages(
          conversationId: tConversationId,
          limit: 50,
        ),
      ).called(1);
    });

    test('should return Right with empty list when no messages', () async {
      when(
        () => mockMessageDataSource.getMessages(
          conversationId: any(named: 'conversationId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => <Message>[]);

      final result = await repository.getMessages(tConversationId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (messages) => expect(messages.isEmpty, true),
      );
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockMessageDataSource.getMessages(
          conversationId: any(named: 'conversationId'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(ServerException('Failed to fetch messages'));

      final result = await repository.getMessages(tConversationId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch messages'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('markAsRead', () {
    const tConversationId = 'conversation-123';

    test('should return Right<Unit> on success', () async {
      when(
        () => mockMessageDataSource.markAsRead(
          conversationId: any(named: 'conversationId'),
        ),
      ).thenAnswer((_) async => unit);

      final result = await repository.markAsRead(tConversationId);

      expect(result.isRight(), true);
      verify(
        () => mockMessageDataSource.markAsRead(conversationId: tConversationId),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockMessageDataSource.markAsRead(
          conversationId: any(named: 'conversationId'),
        ),
      ).thenThrow(ServerException('Failed to mark as read'));

      final result = await repository.markAsRead(tConversationId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to mark as read'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getConversations', () {
    test('should return Right<List<Conversation>> on success', () async {
      when(
        () => mockMessageDataSource.getConversations(),
      ).thenAnswer((_) async => tConversationList);

      final result = await repository.getConversations();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (conversations) => expect(conversations.length, 1),
      );
      verify(() => mockMessageDataSource.getConversations()).called(1);
    });

    test('should return Right with empty list when no conversations', () async {
      when(
        () => mockMessageDataSource.getConversations(),
      ).thenAnswer((_) async => <Conversation>[]);

      final result = await repository.getConversations();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (conversations) => expect(conversations.isEmpty, true),
      );
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockMessageDataSource.getConversations(),
      ).thenThrow(ServerException('Failed to fetch conversations'));

      final result = await repository.getConversations();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch conversations'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('searchUsers', () {
    const tQuery = 'john';

    test('should return Right<List<User>> on success with results', () async {
      when(
        () => mockMessageDataSource.searchUsers(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tUserList);

      final result = await repository.searchUsers(tQuery);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (users) => expect(users.length, 1),
      );
      verify(
        () => mockMessageDataSource.searchUsers(query: tQuery, limit: 3),
      ).called(1);
    });

    test('should return Right<List<User>> with custom limit', () async {
      when(
        () => mockMessageDataSource.searchUsers(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tUserList);

      final result = await repository.searchUsers(tQuery, limit: 10);

      expect(result.isRight(), true);
      verify(
        () => mockMessageDataSource.searchUsers(query: tQuery, limit: 10),
      ).called(1);
    });

    test('should return Right with empty list when no results', () async {
      when(
        () => mockMessageDataSource.searchUsers(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => <User>[]);

      final result = await repository.searchUsers('nonexistent');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (users) => expect(users.isEmpty, true),
      );
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockMessageDataSource.searchUsers(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(ServerException('Failed to search users'));

      final result = await repository.searchUsers(tQuery);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to search users'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('watchMessages', () {
    const tConversationId = 'conversation-123';

    test('should return stream of messages from realtime source', () {
      when(
        () => mockMessageRealTimeDatasource.watchMessages(any()),
      ).thenAnswer((_) => Stream.value(tMessageList));

      final stream = repository.watchMessages(tConversationId);

      expect(stream, isA<Stream<List<Message>>>());
      verify(
        () => mockMessageRealTimeDatasource.watchMessages(tConversationId),
      ).called(1);
    });

    test('should emit message updates', () async {
      final tNewMessage = MessageModel(
        id: 'message-456',
        conversationId: tConversationId,
        senderId: 'user-456',
        content: 'New message',
        createdAt: DateTime(2024, 1, 2),
      );
      final updatedMessageList = [...tMessageList, tNewMessage];

      when(() => mockMessageRealTimeDatasource.watchMessages(any())).thenAnswer(
        (_) => Stream.fromIterable([tMessageList, updatedMessageList]),
      );

      final stream = repository.watchMessages(tConversationId);
      final emissions = await stream.toList();

      expect(emissions.length, 2);
      expect(emissions[0].length, 1);
      expect(emissions[1].length, 2);
    });

    test('should emit empty list when no messages', () async {
      when(
        () => mockMessageRealTimeDatasource.watchMessages(any()),
      ).thenAnswer((_) => Stream.value(<Message>[]));

      final stream = repository.watchMessages(tConversationId);
      final emissions = await stream.toList();

      expect(emissions.length, 1);
      expect(emissions[0].isEmpty, true);
    });
  });
}
