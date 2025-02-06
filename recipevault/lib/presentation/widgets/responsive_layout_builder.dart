// lib/presentation/widgets/responsive_layout_builder.dart
import 'package:flutter/material.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';


class ResponsiveLayoutBuilder extends StatefulWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktopWeb;
  final bool maintainState;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktopWeb,
    this.maintainState = true,
  });

  @override
  State<ResponsiveLayoutBuilder> createState() => _ResponsiveLayoutBuilderState();
}

class _ResponsiveLayoutBuilderState extends State<ResponsiveLayoutBuilder> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add this instance as an observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove this instance as an observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // This is called whenever the window metrics change
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Get current device type
    final deviceType = ResponsiveHelper.whichDevice();
    
    // Apply device-specific padding
    final padding = ResponsiveHelper.screenPadding();
    
    // Build responsive child with appropriate constraints
    Widget buildResponsiveChild(Widget child) {
      return Center(
        child: Container(
          padding: padding,
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.maxContentWidth(),
          ),
          child: child,
        ),
      );
    }

    // Map device type to appropriate layout
    final layouts = {
      ResponsiveSizes.mobile: widget.mobile,
      ResponsiveSizes.tablet: widget.tablet,
      ResponsiveSizes.desktopWeb: widget.desktopWeb,
    };

    return widget.maintainState
        ? IndexedStack(
            index: deviceType.index,
            sizing: StackFit.expand,
            children: ResponsiveSizes.values
                .map((type) => buildResponsiveChild(layouts[type]!))
                .toList(),
          )
        : buildResponsiveChild(layouts[deviceType]!);
  }
}