import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

enum DeviceScreenType { mobile, tablet, desktop }

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppDimensions.tabletBreakpoint) {
      return DeviceScreenType.desktop;
    } else if (width >= AppDimensions.mobileBreakpoint) {
      return DeviceScreenType.tablet;
    }
    return DeviceScreenType.mobile;
  }

  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceScreenType.desktop;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceScreenType.tablet;
  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceScreenType.mobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.tabletBreakpoint) {
          return desktop;
        } else if (constraints.maxWidth >= AppDimensions.mobileBreakpoint) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
