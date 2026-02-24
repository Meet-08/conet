import 'package:conet_app/core/utils/date_formatter.dart';
import 'package:conet_app/feature/notification/domain/entities/notification.dart';
import 'package:conet_app/feature/notification/presentation/widgets/notification_avatar.dart';
import 'package:conet_app/feature/notification/presentation/widgets/notification_type_resolver.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A single notification row in the list.
class NotificationListItem extends StatelessWidget {
  final Notification notification;
  final VoidCallback? onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = NotificationTypeResolver.title(notification);
    final typeIcon = NotificationTypeResolver.icon(notification.type);
    final typeColor = NotificationTypeResolver.iconColor(notification.type);
    final timeAgo = DateFormatter.format(notification.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isSeen
            ? Colors.transparent
            : Colors.blue.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Actor avatar with type icon overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                NotificationAvatar(
                  imageUrl: notification.actorProfilePicUrl,
                  name: notification.actorDisplayName,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: FaIcon(typeIcon, size: 10, color: typeColor),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isSeen
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.content != null &&
                      notification.content!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.content!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Unseen dot indicator
            if (!notification.isSeen)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
