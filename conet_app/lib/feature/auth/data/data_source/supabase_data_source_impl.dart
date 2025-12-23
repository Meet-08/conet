import 'package:bcrypt/bcrypt.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/auth/data/data_source/auth_data_source.dart';
import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:conet_app/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDataSourceImpl implements AuthDataSource {
  final SupabaseClient supabaseClient;

  SupabaseDataSourceImpl({required this.supabaseClient});

  @override
  Session? get currentUserSession => supabaseClient.auth.currentSession;

  @override
  Future<UserModel?> currentUser() async {
    try {
      if (currentUserSession == null) return null;
      final userData = await supabaseClient
          .from('users')
          .select()
          .eq('id', currentUserSession!.user.id)
          .single();

      return UserModel.fromJson(
        userData,
      ).copyWith(email: currentUserSession!.user.email);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final scopes = ["email", "profile"];
      final googleSignIn = GoogleSignIn.instance;

      googleSignIn.initialize(clientId: dotenv.env["IOS_CLIENT_ID"]);

      final googleUser = await googleSignIn.authenticate();
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) throw const AuthException('No ID Token found.');

      final res = await supabaseClient.auth.signInWithIdToken(
        provider: .google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      if (res.user == null) {
        logger.w("User not exist");
        throw ServerException("Login failed");
      }

      return _getUserModel(res.user!.id);
    } on AuthException catch (e) {
      logger.e('AuthException during login: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      logger.e('Error signing in with Google: $e');
      throw ServerException(e.toString());
    }
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

      return _getUserModel(res.user!.id);
    } catch (e) {
      logger.e('Error Verifying OTP to $email: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> addDetails({
    required String username,
    required String password,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        logger.w('No active session found while adding details');
        throw ServerException('User not logged in');
      }
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      await supabaseClient
          .from('users')
          .update({'username': username, 'password': hashedPassword})
          .eq('id', session.user.id);

      return _getUserModel(session.user.id);
    } catch (e) {
      logger.e('Error adding details for user: $e');
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

  Future<UserModel> _getUserModel(String id) async {
    final user = await supabaseClient
        .from("users")
        .select()
        .eq('id', id)
        .single();

    if (user.isEmpty) {
      logger.w('User not found with id: $id');
      throw ServerException('User not found');
    }
    return UserModel.fromJson(user);
  }
}
