import 'package:flutter/material.dart';

/// Phone-first, but keeps forms readable on tablets and in landscape by capping
/// the content width instead of stretching it edge to edge.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.child, this.maxWidth = 640, this.padding});

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

/// Two stat cards per row on a phone, four on a wide screen.
///
/// Height is derived from a minimum tile size so captions never clip.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.minTileHeight = 132,
    this.padding = const EdgeInsets.all(16),
  });

  final List<Widget> children;
  final double spacing;
  final double minTileHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width >= 720 ? 4 : 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = padding.resolve(Directionality.of(context));
        final innerWidth = constraints.maxWidth - insets.horizontal;
        final cardWidth = (innerWidth - spacing * (columns - 1)) / columns;
        final aspect = cardWidth / minTileHeight;

        return GridView.count(
          padding: padding,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspect,
          children: children,
        );
      },
    );
  }
}
