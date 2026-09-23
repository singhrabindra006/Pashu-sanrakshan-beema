import 'package:flutter/material.dart';

import '../../network/api_exceptions.dart';

/// Single place that decides how feedback looks, so no screen rolls its own
/// SnackBar styling.
class AppSnackBar {
  const AppSnackBar._();

  static void error(BuildContext context, String message) =>
      _show(context, message, Theme.of(context).colorScheme.error, Icons.error_outline);

  static void success(BuildContext context, String message) =>
      _show(context, message, Theme.of(context).colorScheme.primary, Icons.check_circle_outline);

  static void info(BuildContext context, String message) =>
      _show(context, message, Theme.of(context).colorScheme.secondary, Icons.info_outline);

  /// Cancellations are user-initiated and must stay silent.
  static void failure(BuildContext context, AppException exception) {
    if (exception is CancelledException) return;
    error(context, exception.message);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
            ],
          ),
        ),
      );
  }
}
