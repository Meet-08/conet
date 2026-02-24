import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/entities/message_page.dart';
import 'package:conet_app/feature/message/domain/entities/message_realtime_event.dart';
import 'package:conet_app/feature/message/domain/usecases/message_create_conversation.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_conversations.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_messages.dart';
import 'package:conet_app/feature/message/domain/usecases/message_mark_as_read.dart';
import 'package:conet_app/feature/message/domain/usecases/message_search_users.dart';
import 'package:conet_app/feature/message/domain/usecases/message_send_message.dart';
import 'package:conet_app/feature/message/domain/usecases/message_watch_conversation_updates.dart';
import 'package:conet_app/feature/message/domain/usecases/message_watch_messages.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageCreateConversation extends Mock
    implements MessageCreateConversation {}

class MockMessageGetConversations extends Mock
    implements MessageGetConversations {}

class MockMessageGetMessages extends Mock implements MessageGetMessages {}

class MockMessageSendMessage extends Mock implements MessageSendMessage {}

class MockMessageMarkAsRead extends Mock implements MessageMarkAsRead {}

class MockMessageWatchMessages extends Mock implements MessageWatchMessages {}

class MockMessageWatchConversationUpdates extends Mock
    implements MessageWatchConversationUpdates {}

class MockMessageSearchUsers extends Mock implements MessageSearchUsers {}

void main() {
  late MessageBloc messageBloc;
  late MockMessageCreateConversation mockCreateConversation;
  late MockMessageGetConversations mockGetConversations;
  late MockMessageGetMessages mockGetMessages;
  late MockMessageSendMessage mockSendMessage;
  late MockMessageMarkAsRead mockMarkAsRead;
  late MockMessageWatchMessages mockWatchMessages;
  late MockMessageWatchConversationUpdates mockWatchConversationUpdates;
  late MockMessageSearchUsers mockSearchUsers;

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

  const tConversation = Conversation(id: 'conversation-123', otherUser: tUser);

  final tMessage = Message(
    id: 'message-123',
    conversationId: 'conversation-123',
    senderId: 'user-123',
    content: 'Test message',
    createdAt: DateTime(2024, 1, 1),
    isRead: false,
  );

  final tConversationList = [tConversation];
  final tMessageList = [tMessage];
  final tMessagePage = MessagePage(
    messages: tMessageList,
    hasMore: true,
    nextBefore: DateTime(2024, 1, 1),
  );
  final tUserList = [tUser];

  setUp(() {
    mockCreateConversation = MockMessageCreateConversation();
    mockGetConversations = MockMessageGetConversations();
    mockGetMessages = MockMessageGetMessages();
    mockSendMessage = MockMessageSendMessage();
    mockMarkAsRead = MockMessageMarkAsRead();
    mockWatchMessages = MockMessageWatchMessages();
    mockWatchConversationUpdates = MockMessageWatchConversationUpdates();
    mockSearchUsers = MockMessageSearchUsers();

    // Stub global subscription
    when(
      () => mockWatchConversationUpdates(),
    ).thenAnswer((_) => const Stream.empty());

    messageBloc = MessageBloc(
      createConversation: mockCreateConversation,
      getConversationsUsecase: mockGetConversations,
      getMessages: mockGetMessages,
      sendMessage: mockSendMessage,
      markAsRead: mockMarkAsRead,
      watchMessages: mockWatchMessages,
      watchConversationUpdates: mockWatchConversationUpdates,
      searchUsers: mockSearchUsers,
      getCurrentUserId: () => 'user-123',
    );
  });

  tearDown(() {
    messageBloc.close();
  });

  test('initial state is MessageState with default values', () {
    expect(messageBloc.state, isA<MessageState>());
    expect(messageBloc.state.conversationStatus, MessageStatus.initial);
    expect(messageBloc.state.messageStatus, MessageStatus.initial);
    expect(messageBloc.state.currentUserId, 'user-123');
  });

  group('MessageConversationsRequested', () {
    blocTest<MessageBloc, MessageState>(
      'emits [loading, success] when getConversations succeeds',
      build: () {
        when(
          () => mockGetConversations(),
        ).thenAnswer((_) async => Right(tConversationList));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageConversationsRequested()),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.conversationStatus,
          'conversationStatus',
          MessageStatus.loading,
        ),
        isA<MessageState>()
            .having(
              (s) => s.conversationStatus,
              'conversationStatus',
              MessageStatus.success,
            )
            .having((s) => s.conversations, 'conversations', tConversationList),
      ],
      verify: (_) {
        verify(() => mockGetConversations()).called(1);
      },
    );

    blocTest<MessageBloc, MessageState>(
      'emits [loading, failure] when getConversations fails',
      build: () {
        when(() => mockGetConversations()).thenAnswer(
          (_) async => Left(AppFailure('Failed to fetch conversations')),
        );
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageConversationsRequested()),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.conversationStatus,
          'conversationStatus',
          MessageStatus.loading,
        ),
        isA<MessageState>()
            .having(
              (s) => s.conversationStatus,
              'conversationStatus',
              MessageStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Failed to fetch conversations',
            ),
      ],
    );
  });

  group('MessageConversationCreated', () {
    const tUserId = 'user-123';

    blocTest<MessageBloc, MessageState>(
      'emits [loading, success] and triggers conversation refresh on success',
      build: () {
        when(
          () => mockCreateConversation(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(tConversation));
        when(
          () => mockGetConversations(),
        ).thenAnswer((_) async => Right(tConversationList));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageConversationCreated(tUserId)),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.conversationStatus,
          'conversationStatus',
          MessageStatus.loading,
        ),
        isA<MessageState>()
            .having(
              (s) => s.conversationStatus,
              'conversationStatus',
              MessageStatus.success,
            )
            .having(
              (s) => s.createdConversation,
              'createdConversation',
              tConversation,
            )
            .having((s) => s.userSuggestions, 'userSuggestions', const [])
            .having((s) => s.isSearchingUsers, 'isSearchingUsers', false),
        isA<MessageState>()
            .having(
              (s) => s.conversationStatus,
              'conversationStatus',
              MessageStatus.success,
            )
            .having((s) => s.conversations, 'conversations', tConversationList),
      ],
      verify: (_) {
        verify(() => mockCreateConversation(userId: tUserId)).called(1);
        verify(() => mockGetConversations()).called(1);
      },
    );

    blocTest<MessageBloc, MessageState>(
      'emits [loading, failure] when createConversation fails',
      build: () {
        when(
          () => mockCreateConversation(userId: any(named: 'userId')),
        ).thenAnswer(
          (_) async => Left(AppFailure('Failed to create conversation')),
        );
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageConversationCreated(tUserId)),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.conversationStatus,
          'conversationStatus',
          MessageStatus.loading,
        ),
        isA<MessageState>()
            .having(
              (s) => s.conversationStatus,
              'conversationStatus',
              MessageStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Failed to create conversation',
            ),
      ],
    );
  });

  group('MessageCreatedConversationHandled', () {
    blocTest<MessageBloc, MessageState>(
      'clears createdConversation from state',
      build: () => messageBloc,
      seed: () => MessageState(createdConversation: tConversation),
      act: (bloc) => bloc.add(MessageCreatedConversationHandled()),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.createdConversation,
          'createdConversation',
          isNull,
        ),
      ],
    );
  });

  group('MessageWatchStarted and MessageRealtimeReceived', () {
    const tConversationId = 'conversation-123';

    blocTest<MessageBloc, MessageState>(
      'starts watching messages and emits updates',
      build: () {
        when(
          () => mockGetMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          ),
        ).thenAnswer((_) async => Right(tMessagePage));
        when(
          () => mockMarkAsRead(conversationId: any(named: 'conversationId')),
        ).thenAnswer((_) async => const Right(unit));
        when(() => mockWatchMessages(any())).thenAnswer(
          (_) => Stream.value(
            MessageRealtimeEvent(
              type: MessageRealtimeEventType.inserted,
              conversationId: tConversationId,
              messageId: tMessage.id,
              message: tMessage,
            ),
          ),
        );
        when(
          () => mockGetConversations(),
        ).thenAnswer((_) async => Right(tConversationList));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageWatchStarted(tConversationId)),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.messageStatus,
          'messageStatus',
          MessageStatus.loading,
        ),
        isA<MessageState>()
            .having(
              (s) => s.messageStatus,
              'messageStatus',
              MessageStatus.success,
            )
            .having((s) => s.messages, 'messages', tMessageList),
        isA<MessageState>()
            .having(
              (s) => s.messageStatus,
              'messageStatus',
              MessageStatus.success,
            )
            .having((s) => s.messages, 'messages', tMessageList),
        isA<MessageState>()
            .having(
              (s) => s.messageStatus,
              'messageStatus',
              MessageStatus.success,
            )
            .having((s) => s.messages, 'messages', tMessageList),
      ],
      verify: (_) {
        verify(
          () => mockGetMessages(
            conversationId: tConversationId,
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          ),
        ).called(1);
        verify(() => mockWatchMessages(tConversationId)).called(1);
        verify(() => mockMarkAsRead(conversationId: tConversationId)).called(1);
      },
    );

    blocTest<MessageBloc, MessageState>(
      'marks as read when MessageListUpdated contains unread messages from others',
      build: () {
        when(
          () => mockGetMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          ),
        ).thenAnswer(
          (_) async => const Right(MessagePage(messages: [], hasMore: true)),
        );
        when(
          () => mockMarkAsRead(conversationId: any(named: 'conversationId')),
        ).thenAnswer((_) async => const Right(unit));
        return messageBloc;
      },
      act: (bloc) => bloc.add(
        MessageRealtimeReceived(
          MessageRealtimeEvent(
            type: MessageRealtimeEventType.inserted,
            conversationId: tConversationId,
            messageId: 'msg-rec',
            message: Message(
              id: 'msg-rec',
              conversationId: tConversationId,
              senderId: 'other-user',
              content: 'Hi',
              createdAt: DateTime.now(),
              isRead: false,
            ),
          ),
          tConversationId,
        ),
      ),
      seed: () => MessageState(activeConversationId: tConversationId),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.messages.length,
          'messages length',
          1,
        ),
        isA<MessageState>().having(
          (s) => s.messages.length,
          'messages length',
          1,
        ),
      ],
      verify: (_) {
        verify(() => mockMarkAsRead(conversationId: tConversationId)).called(1);
      },
    );
  });

  group('MessageSent', () {
    const tConversationId = 'conversation-123';
    const tContent = 'New message';

    blocTest<MessageBloc, MessageState>(
      'calls sendMessage with correct parameters',
      build: () {
        when(
          () => mockSendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
          ),
        ).thenAnswer((_) async => Right(tMessage));
        when(
          () => mockGetConversations(),
        ).thenAnswer((_) async => Right(tConversationList));
        return messageBloc;
      },
      act: (bloc) => bloc.add(
        MessageSent(conversationId: tConversationId, content: tContent),
      ),
      expect: () => [
        isA<MessageState>()
            .having((s) => s.messages.length, 'messages length', 1)
            .having(
              (s) => s.messages.first.status,
              'status',
              MessageDeliveryStatus.pending,
            ),
        isA<MessageState>()
            .having((s) => s.messages.length, 'messages length', 1)
            .having((s) => s.messages.first.id, 'id', tMessage.id),
        isA<MessageState>().having(
          (s) => s.conversationStatus,
          'conversationStatus',
          MessageStatus.loading,
        ),
        isA<MessageState>()
            .having(
              (s) => s.conversationStatus,
              'conversationStatus',
              MessageStatus.success,
            )
            .having((s) => s.conversations, 'conversations', tConversationList),
      ],
      verify: (_) {
        verify(
          () => mockSendMessage(
            conversationId: tConversationId,
            content: tContent,
          ),
        ).called(1);
        verify(() => mockGetConversations()).called(1);
      },
    );

    blocTest<MessageBloc, MessageState>(
      'emits state with error message when sendMessage fails',
      build: () {
        when(
          () => mockSendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Failed to send message')));
        return messageBloc;
      },
      act: (bloc) => bloc.add(
        MessageSent(conversationId: tConversationId, content: tContent),
      ),
      expect: () => [
        isA<MessageState>()
            .having((s) => s.messages.length, 'messages length', 1)
            .having(
              (s) => s.messages.first.status,
              'status',
              MessageDeliveryStatus.pending,
            ),
        isA<MessageState>()
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Failed to send message',
            )
            .having(
              (s) => s.messages.first.status,
              'status',
              MessageDeliveryStatus.error,
            ),
      ],
    );

    blocTest<MessageBloc, MessageState>(
      'sends message with media URLs successfully',
      build: () {
        when(
          () => mockSendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            mediaUrls: any(named: 'mediaUrls'),
          ),
        ).thenAnswer((_) async => Right(tMessage));
        when(
          () => mockGetConversations(),
        ).thenAnswer((_) async => Right(tConversationList));
        return messageBloc;
      },
      act: (bloc) => bloc.add(
        MessageSent(
          conversationId: tConversationId,
          content: tContent,
          mediaUrls: const ['https://example.com/file.pdf'],
        ),
      ),
      expect: () => [
        isA<MessageState>()
            .having((s) => s.messages.length, 'messages length', 1)
            .having(
              (s) => s.messages.first.status,
              'status',
              MessageDeliveryStatus.pending,
            ),
        isA<MessageState>()
            .having((s) => s.messages.length, 'messages length', 1)
            .having((s) => s.messages.first.id, 'id', tMessage.id),
        isA<MessageState>().having(
          (s) => s.conversationStatus,
          'conversationStatus',
          MessageStatus.loading,
        ),
        isA<MessageState>()
            .having(
              (s) => s.conversationStatus,
              'conversationStatus',
              MessageStatus.success,
            )
            .having((s) => s.conversations, 'conversations', tConversationList),
      ],
      verify: (_) {
        verify(
          () => mockSendMessage(
            conversationId: tConversationId,
            content: tContent,
            mediaUrls: const ['https://example.com/file.pdf'],
          ),
        ).called(1);
        verify(() => mockGetConversations()).called(1);
      },
    );
  });

  group('MessageFetchHistoryRequested', () {
    const tConversationId = 'conversation-123';

    blocTest<MessageBloc, MessageState>(
      'fetches message history and updates state',
      build: () {
        when(
          () => mockGetMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          ),
        ).thenAnswer((_) async => Right(tMessagePage));
        return messageBloc;
      },
      seed: () => MessageState(activeConversationId: tConversationId),
      act: (bloc) => bloc.add(MessageFetchHistoryRequested(tConversationId)),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.isFetchingHistory,
          'isFetchingHistory',
          true,
        ),
        isA<MessageState>()
            .having((s) => s.isFetchingHistory, 'isFetchingHistory', false)
            .having((s) => s.messages, 'messages', tMessageList),
      ],
      verify: (_) {
        verify(
          () => mockGetMessages(
            conversationId: tConversationId,
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          ),
        ).called(1);
      },
    );

    blocTest<MessageBloc, MessageState>(
      'emits error message when fetch history fails',
      build: () {
        when(
          () => mockGetMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Failed to fetch history')));
        return messageBloc;
      },
      seed: () => MessageState(activeConversationId: tConversationId),
      act: (bloc) => bloc.add(MessageFetchHistoryRequested(tConversationId)),
      expect: () => [
        isA<MessageState>().having(
          (s) => s.isFetchingHistory,
          'isFetchingHistory',
          true,
        ),
        isA<MessageState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Failed to fetch history',
        ),
      ],
    );
  });

  group('MessageMarkAsReadRequested', () {
    const tConversationId = 'conversation-123';

    blocTest<MessageBloc, MessageState>(
      'calls markAsRead with correct conversationId',
      build: () {
        when(
          () => mockMarkAsRead(conversationId: any(named: 'conversationId')),
        ).thenAnswer((_) async => const Right(unit));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageMarkAsReadRequested(tConversationId)),
      verify: (_) {
        verify(() => mockMarkAsRead(conversationId: tConversationId)).called(1);
      },
    );

    blocTest<MessageBloc, MessageState>(
      'emits error message when markAsRead fails',
      build: () {
        when(
          () => mockMarkAsRead(conversationId: any(named: 'conversationId')),
        ).thenAnswer((_) async => Left(AppFailure('Failed to mark as read')));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageMarkAsReadRequested(tConversationId)),
      expect: () => [
        isA<MessageState>(),
        isA<MessageState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Failed to mark as read',
        ),
      ],
    );
  });

  group('MessageUserSearchRequested', () {
    const tQuery = 'john';

    blocTest<MessageBloc, MessageState>(
      'searches users and updates state with results',
      build: () {
        when(
          () => mockSearchUsers(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Right(tUserList));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageUserSearchRequested(tQuery)),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        isA<MessageState>()
            .having((s) => s.isSearchingUsers, 'isSearchingUsers', true)
            .having((s) => s.userSearchError, 'userSearchError', null),
        isA<MessageState>()
            .having((s) => s.isSearchingUsers, 'isSearchingUsers', false)
            .having((s) => s.userSuggestions, 'userSuggestions', tUserList),
      ],
      verify: (_) {
        verify(() => mockSearchUsers(query: tQuery, limit: 3)).called(1);
      },
    );

    blocTest<MessageBloc, MessageState>(
      'clears suggestions when query is empty',
      build: () => messageBloc,
      act: (bloc) => bloc.add(MessageUserSearchRequested('')),
      expect: () => [
        isA<MessageState>()
            .having((s) => s.userSuggestions, 'userSuggestions', const [])
            .having((s) => s.userSearchError, 'userSearchError', null)
            .having((s) => s.isSearchingUsers, 'isSearchingUsers', false),
      ],
    );

    blocTest<MessageBloc, MessageState>(
      'emits error when search fails',
      build: () {
        when(
          () => mockSearchUsers(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Failed to search users')));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageUserSearchRequested(tQuery)),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        isA<MessageState>()
            .having((s) => s.isSearchingUsers, 'isSearchingUsers', true)
            .having((s) => s.userSearchError, 'userSearchError', null),
        isA<MessageState>()
            .having((s) => s.isSearchingUsers, 'isSearchingUsers', false)
            .having(
              (s) => s.userSearchError,
              'userSearchError',
              'Failed to search users',
            ),
      ],
    );
  });

  group('MessageUserSearchCleared', () {
    blocTest<MessageBloc, MessageState>(
      'clears user search state',
      build: () => messageBloc,
      act: (bloc) => bloc.add(MessageUserSearchCleared()),
      expect: () => [
        isA<MessageState>()
            .having((s) => s.userSuggestions, 'userSuggestions', const [])
            .having((s) => s.userSearchError, 'userSearchError', null)
            .having((s) => s.isSearchingUsers, 'isSearchingUsers', false),
      ],
    );
  });
}
