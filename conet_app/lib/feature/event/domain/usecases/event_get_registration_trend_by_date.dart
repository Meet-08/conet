import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_trend.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetRegistrationTrendByDate {
  final EventRepository _repository;

  EventGetRegistrationTrendByDate({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventRegistrationTrend>> call({
    required String eventId,
    DateTime? from,
    DateTime? to,
  }) {
    return _repository.getRegistrationTrendByDate(
      eventId: eventId,
      from: from,
      to: to,
    );
  }
}
