import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Empty state displayed when there are no notifications.
class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.bellSlash,
              size: 48,
              color: semantic.iconTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: AppTextStyles.headingH3.copyWith(
                color: semantic.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When someone interacts with your posts or profile, you'll see it here.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: semantic.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
