import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/common/usecases/user_search_users.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDioClient extends Mock implements DioClient {}
class MockDio extends Mock implements Dio {}

void main() {
  late UserSearchUsers usecase;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    usecase = UserSearchUsers(dioClient: mockDioClient);
  });

  const tQuery = 'john';

  final tUsersJson = [
    {
      'id': 'user-123',
      'email': 'john@example.com',
      'first_name': 'John',
      'last_name': 'Doe',
      'username': 'johndoe',
      'profile_pic_url': '',
      'user_role': 'user',
    },
  ];

  group('UserSearchUsers', () {
    test('calls /users/search with default limit', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tUsersJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/search'),
        ),
      );

      await usecase(query: tQuery);

      verify(
        () => mockDio.get(
          '/users/search',
          queryParameters: {'query': tQuery, 'limit': 3},
        ),
      ).called(1);
    });

    test('calls /users/search with custom limit', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tUsersJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/search'),
        ),
      );

      await usecase(query: tQuery, limit: 10);

      verify(
        () => mockDio.get(
          '/users/search',
          queryParameters: {'query': tQuery, 'limit': 10},
        ),
      ).called(1);
    });

    test('returns users on success', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tUsersJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/search'),
        ),
      );

      final result = await usecase(query: tQuery);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (users) {
        expect(users.length, 1);
        expect(users.first.username, 'johndoe');
      });
    });

    test('returns empty list when no users match', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: const [],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/search'),
        ),
      );

      final result = await usecase(query: 'none');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (users) => expect(users, isEmpty),
      );
    });

    test('returns failure when response status is not 200', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: const {'message': 'Failed'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/users/search'),
        ),
      );

      final result = await usecase(query: tQuery);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to search users'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
