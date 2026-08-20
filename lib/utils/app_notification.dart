import 'package:flutter/material.dart';

class AppNotification {
  /// Shows a clean, non-intrusive floating notification with a close (X) button.
  /// Automatically clears any previously queued notifications to prevent spam/queuing.
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    SnackBarAction? action,
    Duration duration = const Duration(milliseconds: 2200),
    IconData? icon,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    
    // Clear any previous queued notifications immediately
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        showCloseIcon: true,
        closeIconColor: Colors.white,
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    show(
      context,
      message,
      backgroundColor: Colors.green.shade800,
      icon: Icons.check_circle_outline,
      action: action,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(
      context,
      message,
      backgroundColor: Colors.red.shade800,
      icon: Icons.error_outline,
      action: action,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    show(
      context,
      message,
      backgroundColor: const Color(0xFF0F172A),
      icon: Icons.info_outline,
      action: action,
      duration: duration,
    );
  }
}
