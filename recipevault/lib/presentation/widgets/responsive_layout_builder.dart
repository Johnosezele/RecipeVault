// lib/presentation/widgets/responsive_layout_builder.dart
import 'package:flutter/material.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';

class ResponsiveLayoutBuilder extends StatefulWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktopWeb;
  final bool maintainState;
  final ResponsiveHelper? responsiveHelper;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktopWeb,
    this.maintainState = true,
    this.responsiveHelper,
  });

  @override
  State<ResponsiveLayoutBuilder> createState() => _ResponsiveLayoutBuilderState();
}

class _ResponsiveLayoutBuilderState extends State<ResponsiveLayoutBuilder> with WidgetsBindingObserver {
  late final ResponsiveHelper _responsiveHelper;

  @override
  void initState() {
    super.initState();
    _responsiveHelper = widget.responsiveHelper ?? ResponsiveHelper();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = _responsiveHelper.whichDevice();
    final padding = _responsiveHelper.screenPadding();
    
    // Build responsive child with appropriate constraints
    Widget buildResponsiveChild(Widget child) {
      return Center(
        child: Container(
          padding: padding,
          constraints: BoxConstraints(
            maxWidth: _responsiveHelper.maxContentWidth(),
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