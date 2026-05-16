import 'package:flutter/material.dart';
import 'colors.dart';

class TraumTypography {
  TraumTypography._();

  static const _fontFamilyFallback = ['NotoSansArabic', 'Arial'];

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 52,
          fontWeight: FontWeight.w700,
          color: TraumColors.onBackground,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: TraumColors.onBackground,
        ),
        displaySmall: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: TraumColors.onBackground,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: TraumColors.onBackground,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: TraumColors.onBackground,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TraumColors.onBackground,
        ),
        titleLarge: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: TraumColors.onBackground,
        ),
        titleMedium: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: TraumColors.onBackground,
        ),
        titleSmall: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: TraumColors.onBackground,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: TraumColors.onBackground,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: TraumColors.onBackground,
        ),
        bodySmall: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: TraumColors.onBackgroundMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TraumColors.onBackground,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: TraumColors.onBackgroundMuted,
        ),
        labelSmall: TextStyle(
          fontFamily: 'DMSans',
          fontFamilyFallback: _fontFamilyFallback,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: TraumColors.onBackgroundMuted,
        ),
      );
}
