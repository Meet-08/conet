import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_count.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_count_by_college.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_count_by_course.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late EventGetRegistrationCountByCollege usecaseCollege;
  late EventGetRegistrationCountByCourse usecaseCourse;
  late MockEventRepository mockRepository;

  final tCollegeCounts = [
    const EventRegistrationCount(label: 'Engineering', count: 10),
  ];

  final tCourseCounts = [const EventRegistrationCount(label: 'CS', count: 8)];

  setUp(() {
    mockRepository = MockEventRepository();
    usecaseCollege = EventGetRegistrationCountByCollege(
      repository: mockRepository,
    );
    usecaseCourse = EventGetRegistrationCountByCourse(
      repository: mockRepository,
    );
  });

  group('EventGetRegistrationCountByCollege', () {
    test('should call repository and return counts', () async {
      when(
        () => mockRepository.getRegistrationCountByCollege('event-1'),
      ).thenAnswer((_) async => Right(tCollegeCounts));

      final result = await usecaseCollege('event-1');

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (counts) {
        expect(counts.length, 1);
        expect(counts.first.label, 'Engineering');
      });

      verify(
        () => mockRepository.getRegistrationCountByCollege('event-1'),
      ).called(1);
    });

    test('should return Left<AppFailure> on failure', () async {
      when(
        () => mockRepository.getRegistrationCountByCollege('event-1'),
      ).thenAnswer((_) async => Left(AppFailure('Counts failed')));

      final result = await usecaseCollege('event-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Counts failed'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('EventGetRegistrationCountByCourse', () {
    test('should call repository and return course counts', () async {
      when(
        () => mockRepository.getRegistrationCountByCourse('event-1'),
      ).thenAnswer((_) async => Right(tCourseCounts));

      final result = await usecaseCourse('event-1');

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (counts) {
        expect(counts.length, 1);
        expect(counts.first.label, 'CS');
      });

      verify(
        () => mockRepository.getRegistrationCountByCourse('event-1'),
      ).called(1);
    });

    test('should return Left<AppFailure> on failure', () async {
      when(
        () => mockRepository.getRegistrationCountByCourse('event-1'),
      ).thenAnswer((_) async => Left(AppFailure('Course counts failed')));

      final result = await usecaseCourse('event-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Course counts failed'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
