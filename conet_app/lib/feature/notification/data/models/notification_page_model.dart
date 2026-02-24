import 'package:conet_app/feature/notification/data/models/notification_model.dart';
import 'package:conet_app/feature/notification/domain/entities/notification_page.dart'
    as domain;

class NotificationPageModel {
  final List<NotificationModel> notifications;
  final int unseenCount;
  final String? nextCursor;

  const NotificationPageModel({
    required this.notifications,
    required this.unseenCount,
    this.nextCursor,
  });

  factory NotificationPageModel.fromJson(
    Map<String, dynamic> json, {
    int limit = 20,
  }) {
    final rawList = json['notifications'] as List? ?? [];
    final notifications = rawList
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Derive cursor from the last item if we received a full page
    final String? cursor = notifications.length >= limit
        ? notifications.last.id
        : null;

    return NotificationPageModel(
      notifications: notifications,
      unseenCount: (json['unseenCount'] as num?)?.toInt() ?? 0,
      nextCursor: cursor,
    );
  }

  /// Convert to the domain entity.
  domain.NotificationPage toEntity() {
    return domain.NotificationPage(
      notifications: notifications,
      unseenCount: unseenCount,
      nextCursor: nextCursor,
    );
  }
}
