import 'package:flutter/material.dart';

/// A small green circle that indicates a user is online.
///
/// Intended to be overlaid on top of an avatar via a [Stack].
/// When [isOnline] is `false` the widget renders nothing.
class OnlineIndicator extends StatelessWidget {
  final bool isOnline;

  /// Dot diameter. Defaults to 12.
  final double size;

  /// Border colour drawn around the dot to create contrast with the
  /// avatar underneath. Defaults to [Colors.white].
  final Color borderColor;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
    );
  }
}
