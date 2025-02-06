import 'package:flutter/material.dart';

enum ResponsiveSizes {
  mobile,
  tablet,
  desktopWeb,
}

/// Interface for window metrics provider to enable testing
abstract class WindowMetricsProvider {
  Size getWindowSize();
}

/// Default implementation using Flutter's WidgetsBinding
class DefaultWindowMetricsProvider implements WindowMetricsProvider {
  @override
  Size getWindowSize() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }
}

class ResponsiveHelper {
  final WindowMetricsProvider _metricsProvider;
  
  // Breakpoint constants
  static const double mobileMaxWidth = 600.0;
  static const double tabletMaxWidth = 1024.0;

  ResponsiveHelper([WindowMetricsProvider? metricsProvider]) 
    : _metricsProvider = metricsProvider ?? DefaultWindowMetricsProvider();
  
  ResponsiveSizes whichDevice() {
    final widthInLogicalPixels = _metricsProvider.getWindowSize().width;
    return switch (widthInLogicalPixels) {
      <= mobileMaxWidth => ResponsiveSizes.mobile,
      >= mobileMaxWidth + 1 && <= tabletMaxWidth => ResponsiveSizes.tablet,
      _ => ResponsiveSizes.desktopWeb
    };
  }

  Size currentWindowSize() => _metricsProvider.getWindowSize();

  bool isPortrait() {
    final size = currentWindowSize();
    return size.height > size.width;
  }

  EdgeInsets screenPadding() {
    return switch (whichDevice()) {
      ResponsiveSizes.mobile => const EdgeInsets.all(16.0),
      ResponsiveSizes.tablet => const EdgeInsets.all(24.0),
      ResponsiveSizes.desktopWeb => const EdgeInsets.all(32.0),
    };
  }

  double maxContentWidth() {
    return switch (whichDevice()) {
      ResponsiveSizes.mobile => double.infinity,
      ResponsiveSizes.tablet => 700.0,
      ResponsiveSizes.desktopWeb => 1200.0,
    };
  }

  double splitScreenRatio() {
    return switch (whichDevice()) {
      ResponsiveSizes.mobile => 1.0, // Full width
      ResponsiveSizes.tablet => 0.4, // 40% for list
      ResponsiveSizes.desktopWeb => 0.3, // 30% for list
    };
  }

}