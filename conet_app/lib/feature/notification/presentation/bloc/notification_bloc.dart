import 'dart:async';

import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/notification/domain/entities/notification.dart';
import 'package:conet_app/feature/notification/domain/usecases/get_notifications_usecase.dart';
import 'package:conet_app/feature/notification/domain/usecases/mark_all_as_seen_usecase.dart';
import 'package:conet_app/feature/notification/domain/usecases/watch_notifications_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase _getNotifications;
  final MarkAllAsSeenUseCase _markAllAsSeen;
  final WatchNotificationsUseCase _watchNotifications;

  String? _nextCursor;
  StreamSubscription<void>? _realtimeSubscription;

  NotificationBloc({
    required GetNotificationsUseCase getNotifications,
    required MarkAllAsSeenUseCase markAllAsSeen,
    required WatchNotificationsUseCase watchNotifications,
  }) : _getNotifications = getNotifications,
       _markAllAsSeen = markAllAsSeen,
       _watchNotifications = watchNotifications,
       super(const NotificationState()) {
    on<NotificationLoadEvent>(_onLoad);
    on<NotificationLoadMoreEvent>(_onLoadMore);
    on<NotificationMarkAllSeenEvent>(_onMarkAllSeen);
    on<NotificationRealtimeReceivedEvent>(_onRealtimeReceived);

    _startRealtime();
  }

  // ── Realtime subscription ───────────────────────────────────────

  void _startRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeSubscription?.cancel();
    _realtimeSubscription = _watchNotifications(userId).listen((_) {
      add(const NotificationRealtimeReceivedEvent());
    });
  }

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }

  // ── Load first page ──────────────────────────────────────────

  Future<void> _onLoad(
    NotificationLoadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    _nextCursor = null;

    final result = await _getNotifications(limit: 20);

    AppFailure? failure;
    List<Notification>? notifications;
    int? unseenCount;
    String? cursor;

    result.fold((f) => failure = f, (page) {
      notifications = page.notifications;
      unseenCount = page.unseenCount;
      cursor = page.nextCursor;
    });

    if (failure != null) {
      emit(state.copyWith(isLoading: false, error: failure));
    } else {
      _nextCursor = cursor;
      emit(
        state.copyWith(
          isLoading: false,
          notifications: notifications,
          unseenCount: unseenCount,
          hasReachedEnd: cursor == null,
        ),
      );
    }
  }

  // ── Pagination ───────────────────────────────────────────────

  Future<void> _onLoadMore(
    NotificationLoadMoreEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.isFetchingMore || state.hasReachedEnd) return;

    emit(state.copyWith(isFetchingMore: true, clearError: true));

    final result = await _getNotifications(limit: 20, cursor: _nextCursor);

    AppFailure? failure;
    List<Notification>? newNotifications;
    String? cursor;

    result.fold((f) => failure = f, (page) {
      newNotifications = page.notifications;
      cursor = page.nextCursor;
    });

    if (failure != null) {
      emit(state.copyWith(isFetchingMore: false, error: failure));
    } else {
      _nextCursor = cursor;
      emit(
        state.copyWith(
          isFetchingMore: false,
          notifications: [...state.notifications, ...newNotifications!],
          hasReachedEnd: cursor == null,
        ),
      );
    }
  }

  // ── Mark all as seen ─────────────────────────────────────────

  Future<void> _onMarkAllSeen(
    NotificationMarkAllSeenEvent event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final previousCount = state.unseenCount;
    final updatedList = state.notifications
        .map((n) => n.copyWith(isSeen: true))
        .toList();

    emit(state.copyWith(unseenCount: 0, notifications: updatedList));

    final result = await _markAllAsSeen();

    result.fold(
      (failure) {
        // Rollback on failure
        emit(state.copyWith(unseenCount: previousCount, error: failure));
      },
      (_) {
        // Already optimistically updated — nothing to do
      },
    );
  }

  // ── Realtime refresh (silent — no loading spinner) ────────────────

  Future<void> _onRealtimeReceived(
    NotificationRealtimeReceivedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    // Re-fetch the first page silently (no isLoading flash).
    // This ensures we have complete data including actor info.
    _nextCursor = null;

    final result = await _getNotifications(limit: 20);

    result.fold(
      (_) {}, // Silently ignore errors for background refresh
      (page) {
        _nextCursor = page.nextCursor;
        emit(
          state.copyWith(
            notifications: page.notifications,
            unseenCount: page.unseenCount,
            hasReachedEnd: page.nextCursor == null,
          ),
        );
      },
    );
  }
}
