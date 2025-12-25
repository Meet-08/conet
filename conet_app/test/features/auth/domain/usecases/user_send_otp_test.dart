import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_send_otp.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UserSendOtp usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = UserSendOtp(authRepository: mockAuthRepository);
  });

  const tEmail = 'newuser@example.com';
  const tFirstName = 'Alice';
  const tLastName = 'Johnson';

  group('UserSendOtp', () {
    test(
      'should call sendOtp with correct params including lastName',
      () async {
        when(
          () => mockAuthRepository.sendOtp(
            email: any(named: 'email'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
          ),
        ).thenAnswer((_) async => const Right(true));

        await usecase(
          email: tEmail,
          firstName: tFirstName,
          lastName: tLastName,
        );

        verify(
          () => mockAuthRepository.sendOtp(
            email: tEmail,
            firstName: tFirstName,
            lastName: tLastName,
          ),
        ).called(1);
      },
    );

    test('should call sendOtp without lastName when null', () async {
      when(
        () => mockAuthRepository.sendOtp(
          email: any(named: 'email'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenAnswer((_) async => const Right(true));

      await usecase(email: tEmail, firstName: tFirstName);

      verify(
        () => mockAuthRepository.sendOtp(
          email: tEmail,
          firstName: tFirstName,
          lastName: null,
        ),
      ).called(1);
    });

    test('should return Right<bool> on success', () async {
      when(
        () => mockAuthRepository.sendOtp(
          email: any(named: 'email'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenAnswer((_) async => const Right(true));

      final result = await usecase(email: tEmail, firstName: tFirstName);

      expect(result, const Right(true));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to send OTP');
      when(
        () => mockAuthRepository.sendOtp(
          email: any(named: 'email'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(email: tEmail, firstName: tFirstName);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to send OTP'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
