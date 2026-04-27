import 'package:flutter/material.dart';

class Loader extends StatelessWidget {
  final Color? color;
  final double? size;
  final double strokeWidth;
  final double? value;
  final String? label;
  final TextStyle? labelStyle;

  const Loader({
    super.key,
    this.color,
    this.size,
    this.strokeWidth = 4.0,
    this.value,
    this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;
    final double effectiveSize = size ?? 50;

    final Widget loaderWidget = SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: CircularProgressIndicator(
        value: value,
        color: effectiveColor,
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        backgroundColor: effectiveColor.withValues(alpha: 0.1),
      ),
    );

    if (label != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loaderWidget,
            const SizedBox(height: 16),
            Text(
              label!,
              style:
                  labelStyle ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      );
    }

    return Center(child: loaderWidget);
  }
}
