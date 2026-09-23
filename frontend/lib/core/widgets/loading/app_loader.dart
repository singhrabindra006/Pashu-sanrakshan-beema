import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Blocks interaction while a form submits.
class BlockingProgressOverlay extends StatelessWidget {
  const BlockingProgressOverlay({super.key, required this.isVisible, required this.child, this.message});

  final bool isVisible;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isVisible)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: AppLoader(message: message),
            ),
          ),
      ],
    );
  }
}
