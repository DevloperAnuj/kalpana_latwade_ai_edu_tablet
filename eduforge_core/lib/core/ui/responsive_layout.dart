import 'package:flutter/widgets.dart';

/// Material 3 breakpoints.
enum ScreenSize { compact, medium, expanded }

extension ScreenSizeX on BuildContext {
  ScreenSize get screenSize {
    final w = MediaQuery.sizeOf(this).width;
    if (w < 600) return ScreenSize.compact;
    if (w < 1200) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isMedium => screenSize == ScreenSize.medium;
  bool get isExpanded => screenSize == ScreenSize.expanded;
}

/// Returns a different widget based on screen width breakpoints.
///
/// [compact]  < 600 px  (phones)
/// [medium]   600–1199 px  (tablets in portrait, small desktops)
/// [expanded] ≥ 1200 px  (desktops, tablets in landscape)
///
/// Falls back to the next-narrower layout when a wider one is not provided.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;
    return switch (size) {
      ScreenSize.expanded => expanded ?? medium ?? compact,
      ScreenSize.medium => medium ?? compact,
      ScreenSize.compact => compact,
    };
  }
}

/// Builder variant — passes the resolved [ScreenSize] to [builder].
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) => builder(context, context.screenSize);
}
