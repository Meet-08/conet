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
      final session = currentUserSession;
      if (session == null) return null;

      final userData = await supabaseClient
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();

      return UserModel.fromJson(userData).copyWith(email: session.user.email);
    } catch (e) {
      logger.e('Error getting current user: ${e.toString()}');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      logger.i('Starting Google Sign-In');

      final scopes = ['email', 'profile'];
      final googleSignIn = GoogleSignIn.instance;

      googleSignIn.initialize(
        serverClientId: dotenv.env['WEB_CLIENT_ID'],
        clientId: dotenv.env['IOS_CLIENT_ID'],
      );

      final googleUser = await googleSignIn.authenticate();
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('No ID token returned from Google');
      }

      final res = await supabaseClient.auth.signInWithIdToken(
        provider: .google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      final user = res.user;
      if (user == null) throw ServerException('Google login failed');

      // Check if user exists in 'users' table
      final userData = await supabaseClient
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userData == null) {
        return UserModel.fromJson(user.toJson());
      }

      return UserModel.fromJson(userData).copyWith(email: user.email);
    } on AuthException catch (e) {
      logger.e('Auth error: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      logger.e('Google sign-in error: ${e.toString()}');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) throw ServerException('Login failed');

      return _getUserModel(res.user!.id);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      logger.e("login failed: ${e.toString()}");
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

      final user = res.user;
      if (user == null) {
        throw ServerException('OTP verification failed');
      }

      await Future.delayed(const Duration(seconds: 1));
      logger.i("Email ${user.email}");
      return _getUserModel(user.id);
    } catch (e) {
      logger.e('OTP verification error: ${e.toString()}');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> addDetails({
    required String username,
    String? firstName,
    String? lastName,
    String? password,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User not logged in');
      }

      if (password != null) {
        await supabaseClient.auth.updateUser(
          UserAttributes(password: password),
        );
      }

      final data = <String, dynamic>{
        'username': username,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      };

      await supabaseClient.from('users').update(data).eq('id', session.user.id);

      return _getUserModel(session.user.id);
    } catch (e) {
      logger.e("Error in updating user: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> sendOtp({
    required String email,
    required String firstName,
    String? lastName,
  }) async {
    try {
      await supabaseClient.auth.signInWithOtp(
        email: email,
        data: {
          'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
      );
      return true;
    } catch (e) {
      logger.e('OTP sending error: ${e.toString()}');
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> _getUserModel(String id) async {
    final user = await supabaseClient
        .from('users')
        .select()
        .eq('id', id)
        .single();

    return UserModel.fromJson(user);
  }
}
