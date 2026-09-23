import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
    final style = OutlinedButton.styleFrom(
      foregroundColor: resolved,
      side: BorderSide(color: resolved.withValues(alpha: 0.6)),
      minimumSize: expanded ? const Size.fromHeight(52) : null,
    );

    if (isLoading) {
      return OutlinedButton(
        onPressed: null,
        style: style,
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: resolved),
        ),
      );
    }

    if (icon != null) {
      return OutlinedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 20), label: Text(label));
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: Text(label));
  }
}
