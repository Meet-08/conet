import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:fpdart/fpdart.dart';

class UserSearchUsers {
  final DioClient _dioClient;

  UserSearchUsers({required DioClient dioClient}) : _dioClient = dioClient;

  Future<Either<AppFailure, List<User>>> call({
    required String query,
    int limit = 3,
  }) async {
    try {
      final res = await _dioClient.dio.get(
        '/users/search',
        queryParameters: {'query': query, 'limit': limit},
      );

      if (res.statusCode != 200) {
        throw ServerException('Failed to search users');
      }

      final users = (res.data as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(users);
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(AppErrorHandler.handleException(e)));
    }
  }
}
