import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  // Responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
  }

  // Responsive card margin
  static EdgeInsets getResponsiveCardMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    }
  }

  // Responsive font sizes
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) {
      return baseFontSize * 0.9;
    } else if (isTablet(context)) {
      return baseFontSize;
    } else {
      return baseFontSize * 1.1;
    }
  }

  // Responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    if (isMobile(context)) {
      return baseIconSize;
    } else if (isTablet(context)) {
      return baseIconSize * 1.1;
    } else {
      return baseIconSize * 1.2;
    }
  }

  // Grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  // Chart height based on screen size
  static double getChartHeight(BuildContext context) {
    if (isMobile(context)) {
      return 200.0;
    } else if (isTablet(context)) {
      return 250.0;
    } else {
      return 300.0;
    }
  }

  // Bottom sheet height
  static double getBottomSheetHeight(BuildContext context) {
    final screenHeight = getScreenHeight(context);
    if (isMobile(context)) {
      return screenHeight * 0.9;
    } else {
      return screenHeight * 0.8;
    }
  }

  // Dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return screenWidth * 0.9;
    } else if (isTablet(context)) {
      return 500.0;
    } else {
      return 600.0;
    }
  }

  // Touch target size (minimum 44px for accessibility)
  static double getTouchTargetSize(BuildContext context) {
    return isMobile(context) ? 48.0 : 44.0;
  }

  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isMobile(context)) {
      return baseSpacing * 0.8;
    } else if (isTablet(context)) {
      return baseSpacing;
    } else {
      return baseSpacing * 1.2;
    }
  }

  // Card elevation based on platform
  static double getCardElevation(BuildContext context) {
    return isMobile(context) ? 2.0 : 4.0;
  }

  // Responsive border radius
  static double getBorderRadius(BuildContext context) {
    return isMobile(context) ? 8.0 : 12.0;
  }

  // Safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Check if device has notch or dynamic island
  static bool hasNotch(BuildContext context) {
    return MediaQuery.of(context).padding.top > 24;
  }

  // Responsive list tile content padding
  static EdgeInsets getListTilePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    }
  }

  // Responsive button height
  static double getButtonHeight(BuildContext context) {
    return isMobile(context) ? 48.0 : 44.0;
  }

  // Responsive form field height
  static double getFormFieldHeight(BuildContext context) {
    return isMobile(context) ? 56.0 : 48.0;
  }

  // Get appropriate scroll physics for platform
  static ScrollPhysics getScrollPhysics() {
    return const BouncingScrollPhysics();
  }

  // Responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    return isMobile(context) ? kToolbarHeight : kToolbarHeight + 8;
  }

  // Responsive bottom navigation bar height
  static double getBottomNavHeight(BuildContext context) {
    return isMobile(context) ? 60.0 : 70.0;
  }

  // Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  // Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  // Responsive modal bottom sheet
  static void showResponsiveBottomSheet({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: getBottomSheetHeight(context),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(getBorderRadius(context) * 2),
          ),
        ),
        child: child,
      ),
    );
  }

  // Responsive dialog
  static void showResponsiveDialog({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getBorderRadius(context)),
        ),
        child: Container(
          width: getDialogWidth(context),
          constraints: BoxConstraints(
            maxHeight: getScreenHeight(context) * 0.8,
          ),
          child: child,
        ),
      ),
    );
  }
}

// Extension for easier access to responsive helpers
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  
  double get screenWidth => ResponsiveHelper.getScreenWidth(this);
  double get screenHeight => ResponsiveHelper.getScreenHeight(this);
  
  EdgeInsets get responsivePadding => ResponsiveHelper.getResponsivePadding(this);
  EdgeInsets get responsiveHorizontalPadding => ResponsiveHelper.getResponsiveHorizontalPadding(this);
  EdgeInsets get responsiveCardMargin => ResponsiveHelper.getResponsiveCardMargin(this);
  
  double get touchTargetSize => ResponsiveHelper.getTouchTargetSize(this);
  double get cardElevation => ResponsiveHelper.getCardElevation(this);
  double get borderRadius => ResponsiveHelper.getBorderRadius(this);
  
  bool get hasNotch => ResponsiveHelper.hasNotch(this);
  bool get isKeyboardVisible => ResponsiveHelper.isKeyboardVisible(this);
  double get keyboardHeight => ResponsiveHelper.getKeyboardHeight(this);
}
