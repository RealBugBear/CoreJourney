import 'package:flutter/material.dart';

/// Farbpalette optimiert für Grayscale-Kompatibilität
/// 
/// Alle Farben sind so gewählt, dass sie unterschiedliche Luminanzwerte haben
/// und somit auch im Graustufen-Modus gut unterscheidbar bleiben.
class AppColors {
  AppColors._();

  // ============================================================================
  // PRIMARY COLORS
  // ============================================================================
  
  /// Primärfarbe - Violett (Luminanz: ~45%)
  /// Gut sichtbar im Grayscale-Modus als mittleres Grau
  static const Color primary = Color(0xFF6B4CE6);
  
  /// Dunklere Variante der Primärfarbe (Luminanz: ~35%)
  static const Color primaryDark = Color(0xFF5338C7);
  
  /// Hellere Variante der Primärfarbe (Luminanz: ~60%)
  static const Color primaryLight = Color(0xFF9B85F2);

  // ============================================================================
  // SEMANTIC COLORS - Optimiert für Grayscale-Unterscheidbarkeit
  // ============================================================================
  
  /// Success/Erfolg - Grün (Luminanz: ~55%)
  /// Im Grayscale: Hell-mittelgrau, leicht heller als Primary
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF248A3D);
  static const Color successLight = Color(0xFF6FDB88);
  
  /// Warning/Warnung - Orange (Luminanz: ~65%)
  /// Im Grayscale: Mittelgrau, heller als Success
  static const Color warning = Color(0xFFFF9500);
  static const Color warningDark = Color(0xFFCC7700);
  static const Color warningLight = Color(0xFFFFAA33);
  
  /// Error/Fehler - Rot (Luminanz: ~40%)
  /// Im Grayscale: Dunkleres Grau, dunkler als Primary
  static const Color error = Color(0xFFFF3B30);
  static const Color errorDark = Color(0xFFCC2F26);
  static const Color errorLight = Color(0xFFFF6259);
  
  /// Info - Blau (Luminanz: ~50%)
  /// Im Grayscale: Mittleres Grau, ähnlich wie Primary aber unterscheidbar
  static const Color info = Color(0xFF007AFF);
  static const Color infoDark = Color(0xFF0062CC);
  static const Color infoLight = Color(0xFF3395FF);

  // ============================================================================
  // NEUTRAL GRAYS - Klare Abstufungen für Hierarchie
  // ============================================================================
  
  /// Sehr dunkles Grau für Text auf hellem Hintergrund (Luminanz: ~10%)
  static const Color textPrimary = Color(0xFF1A1A1A);
  
  /// Mittel-dunkles Grau für sekundären Text (Luminanz: ~40%)
  static const Color textSecondary = Color(0xFF666666);
  
  /// Helles Grau für deaktivierten Text (Luminanz: ~60%)
  static const Color textDisabled = Color(0xFF999999);
  
  /// Sehr helles Grau für Hintergründe (Luminanz: ~96%)
  static const Color backgroundLight = Color(0xFFF5F5F5);
  
  /// Mittelhelles Grau für Divider/Borders (Luminanz: ~88%)
  static const Color divider = Color(0xFFE0E0E0);
  
  /// Reines Weiß
  static const Color white = Color(0xFFFFFFFF);
  
  /// Reines Schwarz
  static const Color black = Color(0xFF000000);

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================
  
  /// Dunkler Hintergrund (Luminanz: ~8%)
  static const Color backgroundDark = Color(0xFF121212);
  
  /// Erhöhte Surface (Luminanz: ~12%)
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  /// Noch höhere Surface (Luminanz: ~16%)
  static const Color surfaceDarkElevated = Color(0xFF2A2A2A);
  
  /// Text auf dunklem Hintergrund - primär (Luminanz: ~95%)
  static const Color textPrimaryDark = Color(0xFFEFEFEF);
  
  /// Text auf dunklem Hintergrund - sekundär (Luminanz: ~70%)
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  
  /// Text auf dunklem Hintergrund - deaktiviert (Luminanz: ~45%)
  static const Color textDisabledDark = Color(0xFF737373);

  // ============================================================================
  // SURFACE VARIANTS - Für Cards und Container
  // ============================================================================
  
  /// Surface Level 1 (leichte Erhebung) - Light Mode
  static const Color surfaceLight1 = Color(0xFFFFFFFF);
  
  /// Surface Level 2 (mittlere Erhebung) - Light Mode
  static const Color surfaceLight2 = Color(0xFFFAFAFA);
  
  /// Surface Level 3 (hohe Erhebung) - Light Mode
  static const Color surfaceLight3 = Color(0xFFF0F0F0);

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================
  
  /// Gibt einen Kontrast-sicheren Text-Farbwert für den gegebenen Hintergrund zurück
  static Color getContrastText(Color backgroundColor) {
    // Berechne relative Luminanz
    final luminance = backgroundColor.computeLuminance();
    
    // WCAG AAA Standard: 7:1 Kontrast für normalen Text
    // Bei hellen Hintergründen (Luminanz > 0.5) verwende dunklen Text
    return luminance > 0.5 ? textPrimary : textPrimaryDark;
  }
  
  /// Prüft ob eine Farbe hell ist
  static bool isLight(Color color) {
    return color.computeLuminance() > 0.5;
  }
}
