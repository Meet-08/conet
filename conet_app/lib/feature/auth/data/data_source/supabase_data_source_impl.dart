import 'package:bcrypt/bcrypt.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/auth/data/data_source/auth_data_source.dart';
import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:conet_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDataSourceImpl implements AuthDataSource {
  final SupabaseClient supabaseClient;

  SupabaseDataSourceImpl({required this.supabaseClient});

  @override
  Session? get currentUserSession => supabaseClient.auth.currentSession;

  @override
  Future<UserModel?> currentUser() {
    // TODO: implement currentUser
    throw UnimplementedError();
  }

  @override
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      logger.i('Attempting to log in user with email: $email');
      final user = await supabaseClient
          .from("users")
          .select()
          .eq('email', email)
          .single();

      if (!BCrypt.checkpw(password, user['password'])) {
        logger.w('Invalid password for email: $email');
        throw ServerException('Invalid email or password');
      }

      return UserModel.fromJson(user);
    } on AuthException catch (e) {
      logger.e('AuthException during login: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      logger.e('Error logging in user: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await supabaseClient.auth.verifyOTP(
        type: .email,
        email: email,
        token: token,
      );

      if (res.user == null) {
        logger.w('OTP verification failed: No user returned from Supabase');
        throw ServerException('OTP verification failed');
      }

      return UserModel.fromJson(res.user!.toJson());
    } catch (e) {
      logger.e('Error Verifying OTP to $email: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> sendOtp({required String email}) {
    try {
      logger.i('Sending OTP to email: $email');
      supabaseClient.auth.signInWithOtp(email: email);
      return Future.value(true);
    } catch (e) {
      logger.e('Error sending OTP to $email: $e');
      throw ServerException(e.toString());
    }
  }
}
