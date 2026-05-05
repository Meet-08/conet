import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum CustomCircleAvatarSize { small, medium }

enum AvatarShape { circle, square }

class CustomCircleAvatar extends StatelessWidget {
  final CustomCircleAvatarSize size;
  final String? imageUrl;
  final String? displayName;
  final String? userId;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? radius;
  final Function(String userId)? onTap;
  final AvatarShape shape;

  const CustomCircleAvatar({
    super.key,
    this.size = CustomCircleAvatarSize.medium,
    this.imageUrl,
    this.displayName,
    this.userId,
    this.backgroundColor,
    this.foregroundColor,
    this.radius,
    this.onTap,
    this.shape = AvatarShape.circle,
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
        .take(2)
        .join();
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.semanticColors;

    if (shape == AvatarShape.square) {
      // Square shape for event groups
      final effectiveSize = _effectiveRadius * 2;
      if (imageUrl != null && imageUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: effectiveSize,
            height: effectiveSize,
            color: backgroundColor ?? colorScheme.surface,
            child: Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: backgroundColor ?? colorScheme.primaryContainer,
                  child: Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: semantics.textOnBrand,
                        fontSize: effectiveSize * 0.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: effectiveSize,
          height: effectiveSize,
          color: backgroundColor ?? colorScheme.primaryContainer,
          child: Center(
            child: Text(
              _initials,
              style: TextStyle(
                color: semantics.textOnBrand,
                fontSize: effectiveSize * 0.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    // Circle shape (default)
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
          color: semantics.textOnBrand,
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
        onTap: onTap != null
            ? () => onTap!(userId!)
            : () => context.push('/profile/$userId'),
        child: avatar,
      );
    }

    return avatar;
  }
}
