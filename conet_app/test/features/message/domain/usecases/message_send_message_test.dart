import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:conet_app/feature/message/domain/usecases/message_send_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MessageSendMessage usecase;
  late MockMessageRepository mockMessageRepository;

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    usecase = MessageSendMessage(messageRepository: mockMessageRepository);
  });

  const tConversationId = 'conversation-123';
  const tContent = 'Hello, this is a test message';
  final tMessage = Message(
    id: 'message-123',
    conversationId: tConversationId,
    senderId: 'user-123',
    content: tContent,
    createdAt: DateTime.now(),
  );

  group('MessageSendMessage', () {
    test('should call sendMessage with correct params', () async {
      when(
        () => mockMessageRepository.sendMessage(
          any(),
          any(),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenAnswer((_) async => Right(tMessage));

      await usecase(conversationId: tConversationId, content: tContent);

      verify(
        () => mockMessageRepository.sendMessage(
          tConversationId,
          tContent,
          mediaUrls: null,
        ),
      ).called(1);
    });

    test('should return Right<Message> on success', () async {
      when(
        () => mockMessageRepository.sendMessage(
          any(),
          any(),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenAnswer((_) async => Right(tMessage));

      final result = await usecase(
        conversationId: tConversationId,
        content: tContent,
      );

      expect(result, Right(tMessage));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to send message');
      when(
        () => mockMessageRepository.sendMessage(
          any(),
          any(),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(
        conversationId: tConversationId,
        content: tContent,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to send message'),
        (_) => fail('Expected Left'),
      );
    });

    test('should send message with media URLs successfully', () async {
      // arrange
      const tMediaUrls = [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
      ];
      when(
        () => mockMessageRepository.sendMessage(
          any(),
          any(),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenAnswer((_) async => Right(tMessage));

      // act
      final result = await usecase(
        conversationId: tConversationId,
        content: tContent,
        mediaUrls: tMediaUrls,
      );

      // assert
      expect(result, Right(tMessage));
      verify(
        () => mockMessageRepository.sendMessage(
          tConversationId,
          tContent,
          mediaUrls: tMediaUrls,
        ),
      ).called(1);
    });

    test('should send message with empty media URLs list', () async {
      // arrange
      const tMediaUrls = <String>[];
      when(
        () => mockMessageRepository.sendMessage(
          any(),
          any(),
          mediaUrls: any(named: 'mediaUrls'),
        ),
      ).thenAnswer((_) async => Right(tMessage));

      // act
      final result = await usecase(
        conversationId: tConversationId,
        content: tContent,
        mediaUrls: tMediaUrls,
      );

      // assert
      expect(result, Right(tMessage));
      verify(
        () => mockMessageRepository.sendMessage(
          tConversationId,
          tContent,
          mediaUrls: tMediaUrls,
        ),
      ).called(1);
    });
  });
}
