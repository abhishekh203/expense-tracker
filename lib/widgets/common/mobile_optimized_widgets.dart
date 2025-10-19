import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_helper.dart';

class MobileFriendlyListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;

  const MobileFriendlyListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.contentPadding,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      child: Container(
        constraints: BoxConstraints(
          minHeight: context.touchTargetSize,
        ),
        padding: contentPadding ?? ResponsiveHelper.getListTilePadding(context),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(
                width: context.isMobile ? 40.0 : 48.0,
                height: context.isMobile ? 40.0 : 48.0,
                child: Center(child: leading!),
              ),
              SizedBox(width: context.isMobile ? 12.0 : 16.0),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null) title!,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: context.isMobile ? 8.0 : 12.0),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class TouchFriendlyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double? size;

  const TouchFriendlyIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? (context.isMobile ? 24.0 : 20.0);
    final buttonSize = context.touchTargetSize;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        icon: Icon(icon, size: iconSize),
        onPressed: onPressed,
        tooltip: tooltip,
        color: color,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: buttonSize,
          minHeight: buttonSize,
        ),
      ),
    );
  }
}

class SwipeableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final String? leftSwipeLabel;
  final String? rightSwipeLabel;
  final IconData? leftSwipeIcon;
  final IconData? rightSwipeIcon;
  final Color? leftSwipeColor;
  final Color? rightSwipeColor;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftSwipeLabel,
    this.rightSwipeLabel,
    this.leftSwipeIcon,
    this.rightSwipeIcon,
    this.leftSwipeColor,
    this.rightSwipeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isMobile || (onSwipeLeft == null && onSwipeRight == null)) {
      return child;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: _getDismissDirection(),
      background: _buildSwipeBackground(
        context,
        isLeft: true,
        color: leftSwipeColor ?? Colors.red,
        icon: leftSwipeIcon ?? Icons.delete,
        label: leftSwipeLabel ?? 'Delete',
      ),
      secondaryBackground: onSwipeRight != null
          ? _buildSwipeBackground(
              context,
              isLeft: false,
              color: rightSwipeColor ?? Colors.blue,
              icon: rightSwipeIcon ?? Icons.edit,
              label: rightSwipeLabel ?? 'Edit',
            )
          : null,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd && onSwipeLeft != null) {
          onSwipeLeft!();
        } else if (direction == DismissDirection.endToStart && onSwipeRight != null) {
          onSwipeRight!();
        }
      },
      child: child,
    );
  }

  DismissDirection _getDismissDirection() {
    if (onSwipeLeft != null && onSwipeRight != null) {
      return DismissDirection.horizontal;
    } else if (onSwipeLeft != null) {
      return DismissDirection.startToEnd;
    } else if (onSwipeRight != null) {
      return DismissDirection.endToStart;
    }
    return DismissDirection.none;
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required bool isLeft,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      color: color,
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: context.isMobile ? 28.0 : 24.0,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class HapticFeedbackButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final HapticFeedbackType feedbackType;

  const HapticFeedbackButton({
    super.key,
    required this.child,
    this.onPressed,
    this.feedbackType = HapticFeedbackType.lightImpact,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed != null
          ? () {
              if (context.isMobile) {
                switch (feedbackType) {
                  case HapticFeedbackType.lightImpact:
                    HapticFeedback.lightImpact();
                    break;
                  case HapticFeedbackType.mediumImpact:
                    HapticFeedback.mediumImpact();
                    break;
                  case HapticFeedbackType.heavyImpact:
                    HapticFeedback.heavyImpact();
                    break;
                  case HapticFeedbackType.selectionClick:
                    HapticFeedback.selectionClick();
                    break;
                }
              }
              onPressed!();
            }
          : null,
      child: child,
    );
  }
}

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
}

class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enabled;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || !context.isMobile) {
      return child;
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 60.0,
      strokeWidth: 2.0,
      child: child,
    );
  }
}

class MobileKeyboardPadding extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const MobileKeyboardPadding({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || !context.isMobile) {
      return child;
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.only(
        bottom: context.isKeyboardVisible ? context.keyboardHeight : 0,
      ),
      child: child,
    );
  }
}

class SafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isMobile) {
      return child;
    }

    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

class AdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const AdaptiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeAreaWrapper(
        child: body ?? const SizedBox.shrink(),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: context.isMobile,
    );
  }
}
