import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/usecases/event_add_cohost.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_cohosts.dart';
import 'package:conet_app/feature/event/domain/usecases/event_promote_cohost.dart';
import 'package:conet_app/feature/event/domain/usecases/event_remove_cohost.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventCohostManagementCubit extends Cubit<EventCohostManagementState> {
  final EventGetCohosts _getCohosts;
  final EventAddCohost _addCohost;
  final EventPromoteCohost _promoteCohost;
  final EventRemoveCohost _removeCohost;

  EventCohostManagementCubit({
    required EventGetCohosts getCohosts,
    required EventAddCohost addCohost,
    required EventPromoteCohost promoteCohost,
    required EventRemoveCohost removeCohost,
  }) : _getCohosts = getCohosts,
       _addCohost = addCohost,
       _promoteCohost = promoteCohost,
       _removeCohost = removeCohost,
       super(const EventCohostManagementState());

  Future<void> loadCohosts(String eventId) async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));

    final result = await _getCohosts(eventId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          feedbackMessage: failure.message,
          feedbackIsError: true,
        ),
      ),
      (cohosts) => emit(
        state.copyWith(
          cohosts: cohosts,
          isLoading: false,
          feedbackIsError: false,
          clearFeedback: true,
        ),
      ),
    );
  }

  Future<void> addCohosts(String eventId, List<User> users) async {
    final uniqueUsers = <String, User>{
      for (final user in users) user.id: user,
    }.values.toList(growable: false);

    if (uniqueUsers.isEmpty) return;

    emit(state.copyWith(isMutating: true, clearFeedback: true));

    final addedCohosts = <EventCohost>[];
    for (final user in uniqueUsers) {
      final result = await _addCohost(eventId: eventId, userId: user.id);
      String? failureMessage;

      result.fold(
        (failure) => failureMessage = failure.message,
        (cohost) => addedCohosts.add(cohost),
      );

      if (failureMessage != null) {
        emit(
          state.copyWith(
            isMutating: false,
            feedbackMessage: failureMessage,
            feedbackIsError: true,
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        cohosts: _mergeByUserId(state.cohosts, addedCohosts),
        isMutating: false,
        feedbackMessage: addedCohosts.length == 1
            ? 'Co-host added successfully'
            : 'Co-hosts added successfully',
        feedbackIsError: false,
      ),
    );
  }

  Future<void> removeCohost(String eventId, EventCohost cohost) async {
    emit(state.copyWith(isMutating: true, clearFeedback: true));

    final result = await _removeCohost(eventId: eventId, userId: cohost.userId);
    String? failureMessage;

    result.fold((failure) => failureMessage = failure.message, (_) => null);

    if (failureMessage != null) {
      emit(
        state.copyWith(
          isMutating: false,
          feedbackMessage: failureMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        cohosts: state.cohosts
            .where((item) => item.userId != cohost.userId)
            .toList(growable: false),
        isMutating: false,
        feedbackMessage: '${cohost.displayName} removed as co-host',
        feedbackIsError: false,
      ),
    );
  }

  Future<void> promoteCohost(String eventId, EventCohost cohost) async {
    emit(state.copyWith(isMutating: true, clearFeedback: true));

    final result = await _promoteCohost(eventId: eventId, userId: cohost.userId);
    String? failureMessage;
    EventCohost? updatedCohost;

    result.fold(
      (failure) => failureMessage = failure.message,
      (value) => updatedCohost = value,
    );

    if (failureMessage != null) {
      emit(
        state.copyWith(
          isMutating: false,
          feedbackMessage: failureMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    final promoted = updatedCohost ?? cohost.copyWith(role: 'organizer');
    emit(
      state.copyWith(
        cohosts: _mergeByUserId(state.cohosts, [promoted]),
        isMutating: false,
        feedbackMessage: '${cohost.displayName} promoted to organizer',
        feedbackIsError: false,
      ),
    );
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  List<EventCohost> _mergeByUserId(
    List<EventCohost> existing,
    List<EventCohost> incoming,
  ) {
    final merged = <String, EventCohost>{
      for (final cohost in existing) cohost.userId: cohost,
      for (final cohost in incoming) cohost.userId: cohost,
    };
    return merged.values.toList(growable: false);
  }
}

class EventCohostManagementState {
  final List<EventCohost> cohosts;
  final bool isLoading;
  final bool isMutating;
  final String? feedbackMessage;
  final bool feedbackIsError;

  const EventCohostManagementState({
    this.cohosts = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  EventCohostManagementState copyWith({
    List<EventCohost>? cohosts,
    bool? isLoading,
    bool? isMutating,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return EventCohostManagementState(
      cohosts: cohosts ?? this.cohosts,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage: clearFeedback
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }
}
