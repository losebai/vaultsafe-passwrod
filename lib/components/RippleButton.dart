import 'package:flutter/material.dart';

class RippleButton extends StatelessWidget {
  final String? text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? splashColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final bool enabled;
  final bool block;
  final EdgeInsetsGeometry padding;

  const RippleButton({
    Key? key,
    this.text,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.splashColor,
    this.borderRadius = 8.0,
    this.textStyle,
    this.enabled = true,
    this.block = false,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || onPressed == null;
    final bgColor = isDisabled
        ? Colors.grey[300]
        : backgroundColor ?? Theme.of(context).colorScheme.primary;
    final textColor = isDisabled
        ? Colors.grey[600]
        : Theme.of(context).colorScheme.onPrimary;

    List<Widget> children = [];
    if (icon != null) children.add(icon!);
    if (text != null) {
      if (icon != null) children.add(SizedBox(width: 8));
      children.add(Text(text!, style: textStyle?.copyWith(color: textColor) ?? TextStyle(color: textColor)));
    }

    return InkWell(
      onTap: isDisabled ? null : onPressed,
      splashColor: splashColor ?? Theme.of(context).splashColor,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: block ? double.infinity : null,
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: children.length == 1
            ? children.first
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
      ),
    );
  }
}