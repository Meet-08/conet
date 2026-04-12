import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum CustomCircleAvatarSize { small, medium }

class CustomCircleAvatar extends StatelessWidget {
  final CustomCircleAvatarSize size;
  final String? imageUrl;
  final String? displayName;
  final String? userId;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? radius;

  const CustomCircleAvatar({
    super.key,
    this.size = CustomCircleAvatarSize.medium,
    this.imageUrl,
    this.displayName,
    this.userId,
    this.backgroundColor,
    this.foregroundColor,
    this.radius,
  });

  double get _effectiveRadius {
    if (radius != null) return radius!;
    switch (size) {
      case CustomCircleAvatarSize.small:
        return 12.0;
      case CustomCircleAvatarSize.medium:
        return 20.0;
    }
  }

  String get _initials {
    if (displayName == null || displayName!.isEmpty) return '';
    return displayName!
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: _effectiveRadius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: backgroundColor ?? colorScheme.surface,
      );
    }

    return CircleAvatar(
      radius: _effectiveRadius,
      backgroundColor: backgroundColor ?? colorScheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          color: foregroundColor ?? colorScheme.onPrimaryContainer,
          fontSize: _effectiveRadius * 0.7,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar(context);

    if (userId != null) {
      return GestureDetector(
        onTap: () => context.push('/user-profile', extra: userId),
        child: avatar,
      );
    }

    return avatar;
  }
}
