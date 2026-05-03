import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1024;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) {
      return const EdgeInsets.all(32);
    }
    if (width >= 600) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(16);
  }

  static int dashboardColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) {
      return 4;
    }
    if (width >= 650) {
      return 2;
    }
    return 1;
  }

  static int listColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) {
      return 3;
    }
    if (width >= 800) {
      return 2;
    }
    return 1;
  }

  static double contentMaxWidth(BuildContext context) {
    return isDesktop(context) ? 1120 : double.infinity;
  }

  static double formMaxWidth(BuildContext context) {
    return isDesktop(context) ? 760 : double.infinity;
  }
}

class ResponsiveCenter extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ResponsiveCenter({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
