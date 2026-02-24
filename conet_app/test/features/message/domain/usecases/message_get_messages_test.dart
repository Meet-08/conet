import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/entities/message_page.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MessageGetMessages usecase;
  late MockMessageRepository mockMessageRepository;

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    usecase = MessageGetMessages(messageRepository: mockMessageRepository);
  });

  const tConversationId = 'conversation-123';
  final tMessage = Message(
    id: 'message-123',
    conversationId: tConversationId,
    senderId: 'user-123',
    content: 'Hello, this is a test message',
    createdAt: DateTime(2024, 1, 1),
    isRead: false,
  );

  final tMessageList = [tMessage];

  final tMessagePage = MessagePage(
    messages: tMessageList,
    hasMore: true,
    nextBefore: DateTime(2024, 1, 2),
  );

  final tEmptyMessagePage = const MessagePage(messages: [], hasMore: false);

  group('MessageGetMessages', () {
    test('should call getMessages with correct params', () async {
      when(
        () => mockMessageRepository.getMessages(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tMessagePage));

      await usecase(conversationId: tConversationId);

      verify(
        () => mockMessageRepository.getMessages(tConversationId, limit: 20),
      ).called(1);
    });

    test('should call getMessages with custom limit', () async {
      when(
        () => mockMessageRepository.getMessages(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tMessagePage));

      await usecase(conversationId: tConversationId, limit: 50);

      verify(
        () => mockMessageRepository.getMessages(tConversationId, limit: 50),
      ).called(1);
    });

    test('should return Right<MessagePage> on success', () async {
      when(
        () => mockMessageRepository.getMessages(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tMessagePage));

      final result = await usecase(conversationId: tConversationId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (page) => expect(page.messages.length, 1),
      );
    });

    test(
      'should return Right with empty MessagePage when no messages',
      () async {
        when(
          () => mockMessageRepository.getMessages(
            any(),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Right(tEmptyMessagePage));

        final result = await usecase(conversationId: tConversationId);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (page) => expect(page.messages.isEmpty, true),
        );
      },
    );

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to fetch messages');
      when(
        () => mockMessageRepository.getMessages(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(conversationId: tConversationId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch messages'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return messages with media URLs', () async {
      // arrange
      final tMessageWithMedia = Message(
        id: 'message-456',
        conversationId: tConversationId,
        senderId: 'user-456',
        content: 'Check out these images!',
        createdAt: DateTime(2024, 1, 2),
        isRead: false,
        mediaUrls: const [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ],
      );
      final tPageWithMedia = MessagePage(
        messages: [tMessageWithMedia],
        hasMore: false,
      );
      when(
        () => mockMessageRepository.getMessages(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tPageWithMedia));

      // act
      final result = await usecase(conversationId: tConversationId);

      // assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (page) {
        expect(page.messages.length, 1);
        expect(page.messages.first.mediaUrls.length, 2);
        expect(
          page.messages.first.mediaUrls,
          contains('https://example.com/image1.jpg'),
        );
        expect(
          page.messages.first.mediaUrls,
          contains('https://example.com/image2.jpg'),
        );
      });
    });
  });
}
