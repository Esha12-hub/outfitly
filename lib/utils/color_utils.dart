import 'package:flutter/material.dart';

class ColorUtils {

  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: (opacity * 255).round().toDouble());
  }

  static Color withAlpha(Color color, int alpha) {
    return color.withValues(alpha: alpha.toDouble());
  }

  static Color semiTransparent(Color color) {
    return color.withValues(alpha: 128);
  }

  static Color lighten(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + factor).clamp(0.0, 1.0)).toColor();
  }

  static Color darken(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0)).toColor();
  }
}
