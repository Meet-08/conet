part of 'notification_bloc.dart';

sealed class NotificationEvent {
  const NotificationEvent();
}

/// Initial load of notifications.
class NotificationLoadEvent extends NotificationEvent {
  const NotificationLoadEvent();
}

/// Fetch next page (pagination via cursor).
class NotificationLoadMoreEvent extends NotificationEvent {
  const NotificationLoadMoreEvent();
}

/// Mark all notifications as seen.
class NotificationMarkAllSeenEvent extends NotificationEvent {
  const NotificationMarkAllSeenEvent();
}

/// Internal event triggered by the Supabase realtime subscription
/// when a new POST_LIKE or POST_COMMENT notification is inserted.
class NotificationRealtimeReceivedEvent extends NotificationEvent {
  const NotificationRealtimeReceivedEvent();
}
