import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_conversations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MessageGetConversations usecase;
  late MockMessageRepository mockMessageRepository;

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    usecase = MessageGetConversations(messageRepository: mockMessageRepository);
  });

  const tUser = User(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
  );

  const tConversation = Conversation(id: 'conversation-123', otherUser: tUser);

  final tConversationList = [tConversation];

  group('MessageGetConversations', () {
    test('should call getConversations', () async {
      when(
        () => mockMessageRepository.getConversations(),
      ).thenAnswer((_) async => Right(tConversationList));

      await usecase();

      verify(() => mockMessageRepository.getConversations()).called(1);
    });

    test('should return Right<List<Conversation>> on success', () async {
      when(
        () => mockMessageRepository.getConversations(),
      ).thenAnswer((_) async => Right(tConversationList));

      final result = await usecase();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (conversations) => expect(conversations.length, 1),
      );
    });

    test('should return Right with empty list when no conversations', () async {
      when(
        () => mockMessageRepository.getConversations(),
      ).thenAnswer((_) async => const Right(<Conversation>[]));

      final result = await usecase();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (conversations) => expect(conversations.isEmpty, true),
      );
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to fetch conversations');
      when(
        () => mockMessageRepository.getConversations(),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch conversations'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
