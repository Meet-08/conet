import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:conet_app/feature/message/domain/usecases/message_mark_as_read.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MessageMarkAsRead usecase;
  late MockMessageRepository mockMessageRepository;

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    usecase = MessageMarkAsRead(messageRepository: mockMessageRepository);
  });

  const tConversationId = 'conversation-123';

  group('MessageMarkAsRead', () {
    test('should call markAsRead with correct params', () async {
      when(
        () => mockMessageRepository.markAsRead(any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(conversationId: tConversationId);

      verify(() => mockMessageRepository.markAsRead(tConversationId)).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockMessageRepository.markAsRead(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(conversationId: tConversationId);

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to mark messages as read');
      when(
        () => mockMessageRepository.markAsRead(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(conversationId: tConversationId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to mark messages as read'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
