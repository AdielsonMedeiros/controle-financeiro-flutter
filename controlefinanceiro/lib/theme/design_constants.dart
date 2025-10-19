import 'package:flutter/material.dart';

class DesignConstants {
  // Bordas arredondadas
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;
  
  // Espaçamentos
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  
  // Elevações
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Animações
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Sombras
  static List<BoxShadow> shadowLight(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowMedium(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> shadowHeavy(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
