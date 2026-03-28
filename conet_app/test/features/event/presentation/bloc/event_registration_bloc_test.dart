import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendance_result.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_ticket.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_info.dart';
import 'package:conet_app/feature/event/domain/usecases/event_mark_attendance.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_registration_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventGetRegistrationInfo extends Mock
    implements EventGetRegistrationInfo {}

class MockEventMarkAttendance extends Mock implements EventMarkAttendance {}

void main() {
  late EventRegistrationBloc bloc;
  late MockEventGetRegistrationInfo mockGetRegistrationInfo;
  late MockEventMarkAttendance mockMarkAttendance;

  const tTicket = EventRegistrationTicket(
    eventId: 'event-1',
    userId: 'user-1',
    registrationId: 'reg-1',
  );

  const tAttendanceResult = EventAttendanceResult(
    success: true,
    message: 'Attendance marked',
  );

  setUp(() {
    mockGetRegistrationInfo = MockEventGetRegistrationInfo();
    mockMarkAttendance = MockEventMarkAttendance();

    bloc = EventRegistrationBloc(
      getRegistrationInfo: mockGetRegistrationInfo,
      markAttendance: mockMarkAttendance,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is EventRegistrationInitial', () {
    expect(bloc.state, isA<EventRegistrationInitial>());
  });

  group('EventRegistrationFetchTicketEvent', () {
    blocTest<EventRegistrationBloc, EventRegistrationState>(
      'emits [EventRegistrationLoading, EventRegistrationTicketLoaded] on success',
      build: () {
        when(
          () => mockGetRegistrationInfo('event-1'),
        ).thenAnswer((_) async => const Right(tTicket));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const EventRegistrationFetchTicketEvent('event-1')),
      expect: () => [
        isA<EventRegistrationLoading>(),
        isA<EventRegistrationTicketLoaded>().having(
          (s) => s.ticket.registrationId,
          'registrationId',
          'reg-1',
        ),
      ],
      verify: (_) {
        verify(() => mockGetRegistrationInfo('event-1')).called(1);
      },
    );

    blocTest<EventRegistrationBloc, EventRegistrationState>(
      'emits [EventRegistrationLoading, EventRegistrationFailure] on failure',
      build: () {
        when(
          () => mockGetRegistrationInfo('event-1'),
        ).thenAnswer((_) async => Left(AppFailure('Ticket not found')));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const EventRegistrationFetchTicketEvent('event-1')),
      expect: () => [
        isA<EventRegistrationLoading>(),
        isA<EventRegistrationFailure>().having(
          (s) => s.message,
          'message',
          'Ticket not found',
        ),
      ],
    );
  });

  group('EventRegistrationMarkAttendanceEvent', () {
    blocTest<EventRegistrationBloc, EventRegistrationState>(
      'emits [EventRegistrationAttendanceLoading, EventRegistrationAttendanceSuccess] on success',
      build: () {
        when(
          () => mockMarkAttendance(
            eventId: 'event-1',
            userId: 'user-1',
            registrationId: 'reg-1',
          ),
        ).thenAnswer((_) async => const Right(tAttendanceResult));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const EventRegistrationMarkAttendanceEvent(
          eventId: 'event-1',
          userId: 'user-1',
          registrationId: 'reg-1',
        ),
      ),
      expect: () => [
        isA<EventRegistrationAttendanceLoading>(),
        isA<EventRegistrationAttendanceSuccess>()
            .having((s) => s.result.success, 'success', true)
            .having((s) => s.result.message, 'message', 'Attendance marked'),
      ],
      verify: (_) {
        verify(
          () => mockMarkAttendance(
            eventId: 'event-1',
            userId: 'user-1',
            registrationId: 'reg-1',
          ),
        ).called(1);
      },
    );

    blocTest<EventRegistrationBloc, EventRegistrationState>(
      'emits [EventRegistrationAttendanceLoading, EventRegistrationFailure] on failure',
      build: () {
        when(
          () => mockMarkAttendance(
            eventId: 'event-1',
            userId: 'user-1',
            registrationId: 'reg-1',
          ),
        ).thenAnswer((_) async => Left(AppFailure('Attendance failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const EventRegistrationMarkAttendanceEvent(
          eventId: 'event-1',
          userId: 'user-1',
          registrationId: 'reg-1',
        ),
      ),
      expect: () => [
        isA<EventRegistrationAttendanceLoading>(),
        isA<EventRegistrationFailure>().having(
          (s) => s.message,
          'message',
          'Attendance failed',
        ),
      ],
    );
  });
}
