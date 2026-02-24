import 'package:conet_app/feature/notification/domain/entities/notification.dart';

class NotificationPage {
  final List<Notification> notifications;
  final int unseenCount;
  final String? nextCursor;

  const NotificationPage({
    required this.notifications,
    required this.unseenCount,
    this.nextCursor,
  });
}
