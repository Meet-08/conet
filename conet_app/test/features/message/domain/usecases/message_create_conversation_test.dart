import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:conet_app/feature/message/domain/usecases/message_create_conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MessageCreateConversation usecase;
  late MockMessageRepository mockMessageRepository;

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    usecase = MessageCreateConversation(
      messageRepository: mockMessageRepository,
    );
  });

  const tUserId = 'user-123';
  const tUser = User(
    id: tUserId,
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
    isVerified: true,
  );

  const tConversation = Conversation(id: 'conversation-123', otherUser: tUser);

  group('MessageCreateConversation', () {
    test('should call createConversation with correct params', () async {
      when(
        () => mockMessageRepository.createConversation(any()),
      ).thenAnswer((_) async => const Right(tConversation));

      await usecase(userId: tUserId);

      verify(() => mockMessageRepository.createConversation(tUserId)).called(1);
    });

    test('should return Right<Conversation> on success', () async {
      when(
        () => mockMessageRepository.createConversation(any()),
      ).thenAnswer((_) async => const Right(tConversation));

      final result = await usecase(userId: tUserId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (conversation) => expect(conversation.id, tConversation.id),
      );
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to create conversation');
      when(
        () => mockMessageRepository.createConversation(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(userId: tUserId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to create conversation'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left<AppFailure> when user not found', () async {
      final tFailure = AppFailure('User not found');
      when(
        () => mockMessageRepository.createConversation(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(userId: 'nonexistent-user');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not found'),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'should return Left<AppFailure> when conversation already exists',
      () async {
        final tFailure = AppFailure('Conversation already exists');
        when(
          () => mockMessageRepository.createConversation(any()),
        ).thenAnswer((_) async => Left(tFailure));

        final result = await usecase(userId: tUserId);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure.message, 'Conversation already exists'),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
