import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: <ThemeExtension<dynamic>>[BrandColors(primary: colorScheme.primary, danger: Colors.red.shade600)],
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: <ThemeExtension<dynamic>>[BrandColors(primary: colorScheme.primary, danger: Colors.red.shade400)],
    );
  }
}

class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({required this.primary, required this.danger});

  final Color primary;
  final Color danger;

  @override
  BrandColors copyWith({Color? primary, Color? danger}) {
    return BrandColors(primary: primary ?? this.primary, danger: danger ?? this.danger);
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) {
      return this;
    }
    return BrandColors(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}
