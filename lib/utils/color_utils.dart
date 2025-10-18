import 'package:flutter/material.dart';

class ColorUtils {
  /// Replaces deprecated withOpacity with withValues
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: (opacity * 255).round().toDouble());
  }
  
  /// Creates a color with alpha value
  static Color withAlpha(Color color, int alpha) {
    return color.withValues(alpha: alpha.toDouble());
  }
  
  /// Creates a semi-transparent color
  static Color semiTransparent(Color color) {
    return color.withValues(alpha: 128);
  }
  
  /// Creates a light version of a color
  static Color lighten(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + factor).clamp(0.0, 1.0)).toColor();
  }
  
  /// Creates a dark version of a color
  static Color darken(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0)).toColor();
  }
}
