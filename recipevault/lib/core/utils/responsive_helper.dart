import 'package:flutter/material.dart';

enum ResponsiveSizes {
  mobile,
  tablet,
  desktopWeb,
}

class ResponsiveHelper {
  // Breakpoint constants
  static const double mobileMaxWidth = 600.0;
  static const double tabletMaxWidth = 1024.0;
  
  // Device type detection using FlutterView
  static ResponsiveSizes whichDevice() {
    // Use FlutterView for more efficient size detection
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final physicalSizeWidth = view.physicalSize.width;
    final devicePixelRatio = view.devicePixelRatio;
    final widthInLogicalPixels = physicalSizeWidth / devicePixelRatio;

    // Determine device type using switch expression
    return switch (widthInLogicalPixels) {
      <= mobileMaxWidth => ResponsiveSizes.mobile,
      >= mobileMaxWidth + 1 && <= tabletMaxWidth => ResponsiveSizes.tablet,
      _ => ResponsiveSizes.desktopWeb
    };
  }

  // Get current window size without BuildContext
  static Size currentWindowSize() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  // Check orientation without BuildContext
  static bool isPortrait() {
    final size = currentWindowSize();
    return size.height > size.width;
  }

  // Get appropriate padding based on device type
  static EdgeInsets screenPadding() {
    return switch (whichDevice()) {
      ResponsiveSizes.mobile => const EdgeInsets.all(16.0),
      ResponsiveSizes.tablet => const EdgeInsets.all(24.0),
      ResponsiveSizes.desktopWeb => const EdgeInsets.all(32.0),
    };
  }

  // Get content constraints based on device type
  static double maxContentWidth() {
    return switch (whichDevice()) {
      ResponsiveSizes.mobile => double.infinity,
      ResponsiveSizes.tablet => 700.0,
      ResponsiveSizes.desktopWeb => 1200.0,
    };
  }

  // Get split screen ratio based on device type
  static double splitScreenRatio() {
    return switch (whichDevice()) {
      ResponsiveSizes.mobile => 1.0, // Full width
      ResponsiveSizes.tablet => 0.4, // 40% for list
      ResponsiveSizes.desktopWeb => 0.3, // 30% for list
    };
  }

}