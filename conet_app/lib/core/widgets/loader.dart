import 'dart:math' as math;

import 'package:flutter/material.dart';

enum LoaderType {
  /// Unique bouncy dots (default)
  dots,

  /// Calm pulsing ring
  pulse,

  /// Standard spinner
  spinner,
}

class Loader extends StatelessWidget {
  final Color? color;
  final double? size;
  final double strokeWidth;

  /// Only used for spinner type
  final double? value;
  final String? label;
  final TextStyle? labelStyle;
  final LoaderType type;

  const Loader({
    super.key,
    this.color,
    this.size,
    this.strokeWidth = 4.0,
    this.value,
    this.label,
    this.labelStyle,
    this.type = LoaderType.dots,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Resolve Color
    final effectiveColor = color ?? Theme.of(context).primaryColor;

    // 2. Resolve Size & Type Logic
    // If size is very small (like button icons), force spinner for clarity
    // unless explicitly asked for another type.
    final bool isSmall = (size != null && size! <= 24);
    final LoaderType effectiveType = isSmall ? LoaderType.spinner : type;
    final double effectiveSize =
        size ?? (effectiveType == LoaderType.spinner ? 24 : 50);

    Widget loaderWidget;

    switch (effectiveType) {
      case LoaderType.spinner:
        loaderWidget = SizedBox(
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
        break;
      case LoaderType.pulse:
        loaderWidget = _PulseLoader(color: effectiveColor, size: effectiveSize);
        break;
      case LoaderType.dots:
        loaderWidget = _BouncingDotsLoader(
          color: effectiveColor,
          size: effectiveSize,
        );
        break;
    }

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

class _BouncingDotsLoader extends StatefulWidget {
  final Color color;
  final double size;

  const _BouncingDotsLoader({required this.color, required this.size});

  @override
  State<_BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<_BouncingDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double dotSize = widget.size / 5;

    return SizedBox(
      width: widget.size,
      height: widget.size / 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return _AnimatedDot(
            controller: _controller,
            color: widget.color,
            size: dotSize,
            index: index,
          );
        }),
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double size;
  final int index;

  const _AnimatedDot({
    required this.controller,
    required this.color,
    required this.size,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Each dot has a phase shift
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double t = (controller.value - (index * 0.2)) % 1.0;
        // Sine wave for smooth bounce
        // Only active during first 0.6 of cycle
        final double y = t < 0.6 ? math.sin(t * math.pi / 0.6) : 0;

        return Transform.translate(
          offset: Offset(0, -y * size * 1.5), // Jump up
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8 + (0.2 * y)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _PulseLoader extends StatefulWidget {
  final Color color;
  final double size;

  const _PulseLoader({required this.color, required this.size});

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Build multiple ripples
          ...List.generate(2, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double t = (_controller.value + (index * 0.5)) % 1.0;
                final double scale = 0.4 + (0.6 * t);
                final double opacity = (1.0 - t).clamp(0.0, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity * 0.5,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Static center
          Container(
            width: widget.size * 0.3,
            height: widget.size * 0.3,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
