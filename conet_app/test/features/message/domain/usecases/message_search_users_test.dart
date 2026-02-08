import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:conet_app/feature/message/domain/usecases/message_search_users.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MessageSearchUsers usecase;
  late MockMessageRepository mockMessageRepository;

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    usecase = MessageSearchUsers(messageRepository: mockMessageRepository);
  });

  const tQuery = 'john';
  const tUser = User(
    id: 'user-123',
    email: 'john@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
    isVerified: true,
  );

  final tUserList = [tUser];

  group('MessageSearchUsers', () {
    test('should call searchUsers with correct params', () async {
      when(
        () => mockMessageRepository.searchUsers(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tUserList));

      await usecase(query: tQuery);

      verify(
        () => mockMessageRepository.searchUsers(tQuery, limit: 3),
      ).called(1);
    });

    test('should call searchUsers with custom limit', () async {
      when(
        () => mockMessageRepository.searchUsers(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tUserList));

      await usecase(query: tQuery, limit: 10);

      verify(
        () => mockMessageRepository.searchUsers(tQuery, limit: 10),
      ).called(1);
    });

    test('should return Right<List<User>> on success with results', () async {
      when(
        () => mockMessageRepository.searchUsers(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tUserList));

      final result = await usecase(query: tQuery);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (users) {
        expect(users.length, 1);
        expect(users.first.username, 'johndoe');
      });
    });

    test('should return Right with empty list when no results', () async {
      when(
        () => mockMessageRepository.searchUsers(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right(<User>[]));

      final result = await usecase(query: 'nonexistent');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (users) => expect(users.isEmpty, true),
      );
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to search users');
      when(
        () => mockMessageRepository.searchUsers(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(query: tQuery);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to search users'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
