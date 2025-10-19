import 'package:controlefinanceiro/theme/design_constants.dart';
import 'package:flutter/material.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.gradient,
    this.onTap,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(DesignConstants.spaceLarge),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(
          borderRadius ?? DesignConstants.radiusLarge,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: boxShadow ?? DesignConstants.shadowLight(context),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          borderRadius ?? DesignConstants.radiusLarge,
        ),
        child: card,
      );
    }

    return card;
  }
}

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final double? width;

  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
          ),
          elevation: DesignConstants.elevationHigh,
          shadowColor: (backgroundColor ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.4),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: DesignConstants.spaceMedium),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignConstants.spaceSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: DesignConstants.spaceMedium),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
