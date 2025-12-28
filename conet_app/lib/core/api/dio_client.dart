import 'package:conet_app/core/api/token_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DioClient {
  final Dio _dio;

  Dio get dio => _dio;

  DioClient({required Dio dio, required SupabaseClient supabaseClient})
    : _dio = dio {
    _dio.options.baseUrl = dotenv.env["BACKEND_URL"]!;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.interceptors.add(TokenInterceptor(supabaseClient: supabaseClient));
  }
}
