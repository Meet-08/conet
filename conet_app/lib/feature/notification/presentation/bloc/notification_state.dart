part of 'notification_bloc.dart';

@immutable
class NotificationState extends Equatable {
  final List<Notification> notifications;
  final int unseenCount;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasReachedEnd;
  final AppFailure? error;

  const NotificationState({
    this.notifications = const [],
    this.unseenCount = 0,
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasReachedEnd = false,
    this.error,
  });

  NotificationState copyWith({
    List<Notification>? notifications,
    int? unseenCount,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasReachedEnd,
    AppFailure? error,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unseenCount: unseenCount ?? this.unseenCount,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    unseenCount,
    isLoading,
    isFetchingMore,
    hasReachedEnd,
    error,
  ];
}
