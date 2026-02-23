import 'package:flutter/material.dart';

/// A small rounded badge that displays an integer count.
///
/// * Hides automatically when [count] is 0.
/// * Caps the displayed value at **99+**.
///
/// Designed to be used inside a [Stack] over an icon.
class NotificationBadge extends StatelessWidget {
  final int count;

  /// Badge background colour. Defaults to [Colors.red].
  final Color color;

  /// Badge text colour. Defaults to [Colors.white].
  final Color textColor;

  /// Badge diameter. Defaults to 18.
  final double size;

  const NotificationBadge({
    super.key,
    required this.count,
    this.color = Colors.red,
    this.textColor = Colors.white,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : '$count';

    return Container(
      height: size,
      constraints: BoxConstraints(minWidth: size),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.55,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
