import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Circular avatar that shows the actor's profile picture or initials.
class NotificationAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const NotificationAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: semantic.backgroundSecondary,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: semantic.backgroundTertiary,
      child: Text(
        _initials,
        style: AppTextStyles.label.copyWith(
          fontSize: radius * 0.7,
          fontWeight: AppTypographyTokens.weightSemibold,
          color: semantic.textSecondary,
        ),
      ),
    );
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
