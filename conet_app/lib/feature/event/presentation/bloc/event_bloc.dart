import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_by_id.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_my_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_my_organized_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_published_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_publish.dart';
import 'package:conet_app/feature/event/domain/usecases/event_register.dart';
import 'package:conet_app/feature/event/domain/usecases/event_save_draft.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'event_event.dart';
part 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventGetById _getById;
  final EventGetPublishedEvents _getPublishedEvents;
  final EventGetMyEvents _getMyEvents;
  final EventGetMyOrganizedEvents _getMyOrganizedEvents;
  final EventPublish _publishEvent;
  final EventRegister _registerEvent;
  final EventSaveDraft _saveDraft;

  String? _nextCursor;
  String? _myEventsNextCursor;
  String _myEventsType = 'upcoming';
  String? _organizedNextCursor;
  String? _organizedStatus;

  EventBloc({
    required EventGetById getById,
    required EventGetPublishedEvents getPublishedEvents,
    required EventGetMyEvents getMyEvents,
    required EventGetMyOrganizedEvents getMyOrganizedEvents,
    required EventPublish publishEvent,
    required EventRegister registerEvent,
    required EventSaveDraft saveDraft,
  }) : _getById = getById,
       _getPublishedEvents = getPublishedEvents,
       _getMyEvents = getMyEvents,
       _getMyOrganizedEvents = getMyOrganizedEvents,
       _publishEvent = publishEvent,
       _registerEvent = registerEvent,
       _saveDraft = saveDraft,
       super(EventInitial()) {
    on<EventFetchByIdEvent>(_onFetchById);
    on<EventFetchPublishedEventsEvent>(_onFetchPublishedEvents);
    on<EventFetchMorePublishedEventsEvent>(_onFetchMorePublishedEvents);
    on<EventFetchMyEventsEvent>(_onFetchMyEvents);
    on<EventFetchMoreMyEventsEvent>(_onFetchMoreMyEvents);
    on<EventFetchMyOrganizedEventsEvent>(_onFetchMyOrganizedEvents);
    on<EventFetchMoreMyOrganizedEventsEvent>(_onFetchMoreMyOrganizedEvents);
    on<EventPublishEvent>(_onPublish);
    on<EventRegisterEvent>(_onRegister);
    on<EventSaveDraftEvent>(_onSaveDraft);
  }

  Future<void> _onFetchById(
    EventFetchByIdEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventDetailLoading());

    final result = await _getById(event.eventId);
    result.fold(
      (failure) => emit(EventDetailFailure(failure.message)),
      (event) => emit(EventDetailLoaded(event)),
    );
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

  Future<void> _onFetchMyEvents(
    EventFetchMyEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(MyEventsLoading());

    _myEventsType = event.type;
    _myEventsNextCursor = null;

    final result = await _getMyEvents(
      type: event.type,
      cursor: event.cursor,
      limit: event.limit,
    );

    String? failureMessage;
    MyEventsLoaded? loaded;

    result.fold((failure) => failureMessage = failure.message, (page) {
      _myEventsNextCursor = page.nextCursor;
      loaded = MyEventsLoaded(
        type: event.type,
        events: page.events,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        pageSize: event.limit,
      );
    });

    if (failureMessage != null) {
      emit(MyEventsFailure(failureMessage!));
    } else {
      emit(loaded!);
    }
  }

  Future<void> _onFetchMoreMyEvents(
    EventFetchMoreMyEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    if (state is! MyEventsLoaded) return;
    final current = state as MyEventsLoaded;
    if (!current.hasMore || _myEventsNextCursor == null) return;

    final result = await _getMyEvents(
      type: _myEventsType,
      cursor: _myEventsNextCursor,
      limit: current.pageSize,
    );

    result.fold((failure) {}, (page) {
      _myEventsNextCursor = page.nextCursor;
      emit(
        current.copyWith(
          events: [...current.events, ...page.events],
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        ),
      );
    });
  }

  Future<void> _onFetchMyOrganizedEvents(
    EventFetchMyOrganizedEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(MyOrganizedEventsLoading());

    _organizedStatus = event.status;
    _organizedNextCursor = null;

    final result = await _getMyOrganizedEvents(
      status: event.status,
      cursor: event.cursor,
      limit: event.limit,
    );

    String? failureMessage;
    MyOrganizedEventsLoaded? loaded;

    result.fold((failure) => failureMessage = failure.message, (page) {
      _organizedNextCursor = page.nextCursor;
      loaded = MyOrganizedEventsLoaded(
        status: event.status,
        events: page.events,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        pageSize: event.limit,
      );
    });

    if (failureMessage != null) {
      emit(MyOrganizedEventsFailure(failureMessage!));
    } else {
      emit(loaded!);
    }
  }

  Future<void> _onFetchMoreMyOrganizedEvents(
    EventFetchMoreMyOrganizedEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    if (state is! MyOrganizedEventsLoaded) return;
    final current = state as MyOrganizedEventsLoaded;
    if (!current.hasMore || _organizedNextCursor == null) return;

    final result = await _getMyOrganizedEvents(
      status: _organizedStatus,
      cursor: _organizedNextCursor,
      limit: current.pageSize,
    );

    result.fold((failure) {}, (page) {
      _organizedNextCursor = page.nextCursor;
      emit(
        current.copyWith(
          events: [...current.events, ...page.events],
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        ),
      );
    });
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

  Future<void> _onRegister(
    EventRegisterEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventRegistrationLoading());

    final result = await _registerEvent(event.eventId);
    result.fold(
      (failure) => emit(EventRegistrationFailure(failure.message)),
      (event) => emit(EventRegistrationSuccess(event)),
    );
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
