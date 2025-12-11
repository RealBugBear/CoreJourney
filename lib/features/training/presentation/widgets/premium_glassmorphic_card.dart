import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium glassmorphic card widget with frosted glass effect
/// 
/// Perfect for creating modern, sleek UI elements with depth and transparency
class PremiumGlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double borderWidth;

  const PremiumGlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 20,
    this.opacity = 0.15,
    this.padding,
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? 
                     theme.colorScheme.onSurface.withOpacity(0.1),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.05),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
