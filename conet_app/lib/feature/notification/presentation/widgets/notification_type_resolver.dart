import 'package:conet_app/feature/notification/domain/entities/notification.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Resolves a human-readable title for a notification based on its type.
class NotificationTypeResolver {
  static String title(Notification notification) {
    switch (notification.type) {
      case 'POST_LIKE':
        return '${notification.actorDisplayName} liked your post';
      case 'POST_COMMENT':
        return '${notification.actorDisplayName} commented on your post';
      case 'NEW_MESSAGE':
        return '${notification.actorDisplayName} sent you a message';
      case 'FOLLOW':
        return '${notification.actorDisplayName} started following you';
      default:
        return '${notification.actorDisplayName} sent you a notification';
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case 'POST_LIKE':
        return FontAwesomeIcons.solidHeart;
      case 'POST_COMMENT':
        return FontAwesomeIcons.solidComment;
      case 'NEW_MESSAGE':
        return FontAwesomeIcons.solidEnvelope;
      case 'FOLLOW':
        return FontAwesomeIcons.userPlus;
      default:
        return FontAwesomeIcons.solidBell;
    }
  }

  static Color iconColor(String type) {
    switch (type) {
      case 'POST_LIKE':
        return Colors.red;
      case 'POST_COMMENT':
        return Colors.blue;
      case 'NEW_MESSAGE':
        return Colors.green;
      case 'FOLLOW':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
