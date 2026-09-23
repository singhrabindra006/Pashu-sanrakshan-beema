import 'package:flutter/material.dart';

import '../buttons/secondary_button.dart';

/// Used for both "nothing here yet" and "something went wrong", because the
/// layout is identical and only the icon/colour changes.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  const EmptyState.error({
    super.key,
    required this.title,
    this.message,
    this.actionLabel = 'Try again',
    this.onAction,
  })  : icon = Icons.error_outline,
        isError = true;

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isError ? scheme.error : scheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: accent),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: SecondaryButton(label: actionLabel!, onPressed: onAction, color: accent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
