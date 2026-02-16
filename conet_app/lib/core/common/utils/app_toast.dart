import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor;
    IconData icon;
    Color textColor;

    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        textColor = Colors.white;
        break;
      case ToastType.error:
        backgroundColor = colorScheme.error;
        icon = Icons.error_outline;
        textColor = colorScheme.onError;
        break;
      case ToastType.warning:
        backgroundColor = Colors.amber.shade700;
        icon = Icons.warning_amber_outlined;
        textColor = Colors.white;
        break;
      case ToastType.info:
        backgroundColor = colorScheme.inverseSurface;
        icon = Icons.info_outline;
        textColor = colorScheme.onInverseSurface;
        break;
    }

    ScaffoldMessenger.of(context).clearSnackBars(); // Clear existing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(seconds: 4),
        showCloseIcon: true,
        closeIconColor: textColor,
      ),
    );
  }

  // Convenience methods
  static void showSuccess(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);
  static void showError(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);
  static void showWarning(BuildContext context, String message) =>
      show(context, message, type: ToastType.warning);
  static void showInfo(BuildContext context, String message) =>
      show(context, message, type: ToastType.info);
}
