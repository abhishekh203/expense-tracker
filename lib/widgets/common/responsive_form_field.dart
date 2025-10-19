import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_helper.dart';

class ResponsiveFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? contentPadding;
  final bool autofocus;

  const ResponsiveFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autovalidateMode,
    this.focusNode,
    this.textInputAction,
    this.contentPadding,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null && context.isMobile) ...[
          Text(
            labelText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.0),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onTap: onTap,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          autovalidateMode: autovalidateMode,
          focusNode: focusNode,
          textInputAction: textInputAction,
          autofocus: autofocus,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16.0),
          ),
          decoration: InputDecoration(
            labelText: context.isMobile ? null : labelText,
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: contentPadding ?? EdgeInsets.symmetric(
              horizontal: context.isMobile ? 16.0 : 12.0,
              vertical: context.isMobile ? 16.0 : 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                width: context.isMobile ? 1.5 : 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: context.isMobile ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: context.isMobile ? 2.0 : 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: context.isMobile ? 2.0 : 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: context.isMobile ? 2.0 : 1.5,
              ),
            ),
            filled: true,
            fillColor: context.isMobile 
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class ResponsiveDropdownField<T> extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final double? menuMaxHeight;

  const ResponsiveDropdownField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.menuMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null && context.isMobile) ...[
          Text(
            labelText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.0),
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16.0),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          menuMaxHeight: menuMaxHeight ?? (context.isMobile ? 300.0 : 400.0),
          decoration: InputDecoration(
            labelText: context.isMobile ? null : labelText,
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: contentPadding ?? EdgeInsets.symmetric(
              horizontal: context.isMobile ? 16.0 : 12.0,
              vertical: context.isMobile ? 16.0 : 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                width: context.isMobile ? 1.5 : 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: context.isMobile ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: context.isMobile ? 2.0 : 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: context.isMobile ? 2.0 : 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: context.isMobile ? 2.0 : 1.5,
              ),
            ),
            filled: true,
            fillColor: context.isMobile 
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final Widget? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? ResponsiveHelper.getButtonHeight(context);
    
    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPrimary 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    if (isPrimary) {
      return SizedBox(
        width: width,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: padding ?? EdgeInsets.symmetric(
              horizontal: context.isMobile ? 24.0 : 20.0,
              vertical: context.isMobile ? 16.0 : 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
            ),
            elevation: context.cardElevation,
          ),
          child: child,
        ),
      );
    } else {
      return SizedBox(
        width: width,
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding ?? EdgeInsets.symmetric(
              horizontal: context.isMobile ? 24.0 : 20.0,
              vertical: context.isMobile ? 16.0 : 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
            ),
            side: BorderSide(
              width: context.isMobile ? 1.5 : 1.0,
            ),
          ),
          child: child,
        ),
      );
    }
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: context.cardElevation,
      color: color,
      margin: margin ?? context.responsiveCardMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: Padding(
        padding: padding ?? context.responsivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.borderRadius),
        child: card,
      );
    }

    return card;
  }
}
