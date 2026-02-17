import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthDataSource {
  Session? get currentUserSession;

  Future<UserModel?> currentUser();

  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel> addDetails({
    required String username,
    String? firstName,
    String? lastName,
    String? password,
  });

  Future<UserModel> signInWithGoogle();

  Future<UserModel> verifyOtp({required String email, required String token});

  Future<bool> sendOtp({
    required String email,
    required String firstName,
    String? lastName,
  });

  /// Checks if a username is available (not already taken)
  Future<bool> checkUsernameAvailable(String username);

  Future<void> logout();
}
