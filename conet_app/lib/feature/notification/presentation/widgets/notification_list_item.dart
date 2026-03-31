import 'package:conet_app/core/theme/theme.dart';
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
    final semantic = context.semanticColors;
    final title = NotificationTypeResolver.title(notification);
    final typeIcon = NotificationTypeResolver.icon(notification.type);
    final typeColor = NotificationTypeResolver.iconColor(
      notification.type,
      semantic,
    );
    final timeAgo = DateFormatter.format(notification.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isSeen
            ? Colors.transparent
            : semantic.backgroundSelected.withValues(alpha: 0.3),
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
                      color: semantic.surfaceBase,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: semantic.backgroundBackdrop.withValues(
                            alpha: 0.16,
                          ),
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
                    style: AppTextStyles.label.copyWith(
                      fontWeight: notification.isSeen
                          ? AppTypographyTokens.weightRegular
                          : AppTypographyTokens.weightSemibold,
                      color: semantic.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.content != null &&
                      notification.content!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.content!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: semantic.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: AppTextStyles.caption.copyWith(
                      color: semantic.textTertiary,
                    ),
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
                  decoration: BoxDecoration(
                    color: semantic.iconSelected,
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
