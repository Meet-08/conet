import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_verify_otp.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UserVerifyOtp usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = UserVerifyOtp(authRepository: mockAuthRepository);
  });

  const tEmail = 'user@example.com';
  const tOtp = '123456';
  const tUser = User(
    id: 'verified-user-789',
    email: 'user@example.com',
    firstName: 'Bob',
    lastName: 'Wilson',
    username: 'bobwilson',
    profilePicUrl: '',
    userRole: UserRole.user,
    isVerified: true,
  );

  group('UserVerifyOtp', () {
    test('should call verifyOtp with correct params', () async {
      when(
        () => mockAuthRepository.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      await usecase(email: tEmail, otp: tOtp);

      verify(
        () => mockAuthRepository.verifyOtp(email: tEmail, token: tOtp),
      ).called(1);
    });

    test('should return Right<User> on success', () async {
      when(
        () => mockAuthRepository.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await usecase(email: tEmail, otp: tOtp);

      expect(result, const Right(tUser));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Invalid OTP');
      when(
        () => mockAuthRepository.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(email: tEmail, otp: tOtp);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Invalid OTP'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
