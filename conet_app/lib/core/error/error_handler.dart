import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorHandler {
  static String handleException(dynamic e) {
    if (e is AuthException) {
      return e.message;
    }
    if (e is PostgrestException) {
      return e.message;
    }
    if (e is StorageException) {
      return e.message;
    }
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return "Connection timeout with server";
        case DioExceptionType.sendTimeout:
          return "Send timeout in association with server";
        case DioExceptionType.receiveTimeout:
          return "Receive timeout in connection with server";
        case DioExceptionType.badResponse:
          if (e.response?.data != null && e.response?.data is Map) {
            final data = e.response?.data as Map<String, dynamic>;
            return data['message'] ?? data['error'] ?? "Something went wrong";
          }
          return e.response?.statusMessage ?? "Bad response from server";
        case DioExceptionType.cancel:
          return "Request to server was cancelled";
        case DioExceptionType.connectionError:
          return "No internet connection";
        case DioExceptionType.unknown:
          return "Unexpected error occurred";
        default:
          return "Something went wrong";
      }
    }
    return e.toString();
  }
}
