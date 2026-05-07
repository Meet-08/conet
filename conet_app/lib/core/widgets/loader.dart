import 'package:conet_app/core/theme/theme.dart';
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
    final semantic = context.semanticColors;
    final effectiveColor = color ?? semantic.backgroundBrand;
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
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: semantic.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
      );
    }

    return Center(child: loaderWidget);
  }
}
