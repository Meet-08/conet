import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_published_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_publish.dart';
import 'package:conet_app/feature/event/domain/usecases/event_save_draft.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'event_event.dart';
part 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventGetPublishedEvents _getPublishedEvents;
  final EventPublish _publishEvent;
  final EventSaveDraft _saveDraft;

  String? _nextCursor;

  EventBloc({
    required EventGetPublishedEvents getPublishedEvents,
    required EventPublish publishEvent,
    required EventSaveDraft saveDraft,
  }) : _getPublishedEvents = getPublishedEvents,
       _publishEvent = publishEvent,
       _saveDraft = saveDraft,
       super(EventInitial()) {
    on<EventFetchPublishedEventsEvent>(_onFetchPublishedEvents);
    on<EventFetchMorePublishedEventsEvent>(_onFetchMorePublishedEvents);
    on<EventPublishEvent>(_onPublish);
    on<EventSaveDraftEvent>(_onSaveDraft);
  }

  Future<void> _onFetchPublishedEvents(
    EventFetchPublishedEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    _nextCursor = null;

    final result = await _getPublishedEvents(
      cursor: event.cursor,
      category: event.category,
      locationType: event.locationType,
      dateFrom: event.dateFrom,
      dateTo: event.dateTo,
      search: event.search,
    );

    String? failureMessage;
    EventLoaded? loaded;

    result.fold((failure) => failureMessage = failure.message, (page) {
      _nextCursor = page.nextCursor;
      loaded = EventLoaded(
        events: page.events,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    });

    if (failureMessage != null) {
      emit(EventFailure(failureMessage!));
    } else {
      emit(loaded!);
    }
  }

  Future<void> _onFetchMorePublishedEvents(
    EventFetchMorePublishedEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    if (state is! EventLoaded) return;
    final current = state as EventLoaded;
    if (!current.hasMore || _nextCursor == null) return;

    final result = await _getPublishedEvents(cursor: _nextCursor);

    result.fold(
      (failure) {}, // silently ignore pagination errors
      (page) {
        _nextCursor = page.nextCursor;
        emit(
          current.copyWith(
            events: [...current.events, ...page.events],
            nextCursor: page.nextCursor,
            hasMore: page.hasMore,
          ),
        );
      },
    );
  }

  Future<void> _onPublish(
    EventPublishEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventCreateLoading());

    final result = await _publishEvent(event.payload);

    String? failureMessage;
    Event? created;

    result.fold(
      (failure) => failureMessage = failure.message,
      (e) => created = e,
    );

    if (failureMessage != null) {
      emit(EventCreateFailure(failureMessage!));
    } else {
      emit(EventCreateSuccess(event: created!, isDraft: false));
    }
  }

  Future<void> _onSaveDraft(
    EventSaveDraftEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventCreateLoading());

    final result = await _saveDraft(event.payload);

    String? failureMessage;
    Event? created;

    result.fold(
      (failure) => failureMessage = failure.message,
      (e) => created = e,
    );

    if (failureMessage != null) {
      emit(EventCreateFailure(failureMessage!));
    } else {
      emit(EventCreateSuccess(event: created!, isDraft: true));
    }
  }
}
