import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interceptor that appends the Authorization header with the Supabase access token
/// to every outgoing HTTP request.
class TokenInterceptor extends Interceptor {
  final SupabaseClient supabaseClient;

  TokenInterceptor({required this.supabaseClient});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = supabaseClient.auth.currentSession;

    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final session = await supabaseClient.auth.refreshSession();

        if (session.session != null) {
          final newToken = session.session!.accessToken;

          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        // refresh failed → logout or redirect
      }
    }

    return handler.next(err);
  }
}
