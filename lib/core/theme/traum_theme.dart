import 'package:flutter/material.dart';
import 'colors.dart';
import 'radius.dart';
import 'typography.dart';

class TraumTheme {
  TraumTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: TraumColors.coralOrange,
          secondary: TraumColors.cyanBlue,
          tertiary: TraumColors.lavender,
          surface: TraumColors.surface,
          error: TraumColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: TraumColors.onBackground,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: TraumColors.background,
        textTheme: TraumTypography.textTheme,
        fontFamily: 'DMSans',
        cardTheme: CardThemeData(
          color: TraumColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: TraumColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: TraumColors.onBackground,
          ),
          iconTheme: IconThemeData(color: TraumColors.onBackground),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: TraumColors.bottomNav,
          selectedItemColor: TraumColors.coralOrange,
          unselectedItemColor: TraumColors.onBackgroundMuted,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TraumColors.coralOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TraumRadius.button),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: TraumColors.coralOrange,
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: TraumColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TraumRadius.input),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TraumRadius.input),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TraumRadius.input),
            borderSide: const BorderSide(
              color: TraumColors.coralOrange,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TraumRadius.input),
            borderSide: const BorderSide(
              color: TraumColors.error,
              width: 1.5,
            ),
          ),
          hintStyle: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 14,
          ),
          labelStyle: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TraumColors.coralOrange;
            }
            return TraumColors.onBackgroundMuted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TraumColors.coralDim;
            }
            return TraumColors.surfaceVariant;
          }),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TraumColors.coralOrange;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: TraumColors.onBackgroundMuted, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: TraumColors.surfaceVariant,
          selectedColor: TraumColors.coralDim,
          labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            color: TraumColors.onBackground,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TraumRadius.chip),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: TraumColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TraumRadius.dialog),
          ),
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: TraumColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(TraumRadius.card),
            ),
          ),
          elevation: 0,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.06),
          thickness: 1,
          space: 1,
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: TraumColors.coralOrange,
          labelColor: TraumColors.coralOrange,
          unselectedLabelColor: TraumColors.onBackgroundMuted,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: TraumColors.coralOrange,
          linearTrackColor: TraumColors.surfaceVariant,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: TraumColors.surfaceElevated,
          contentTextStyle: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: TraumColors.coralOrange,
          secondary: TraumColors.cyanBlue,
        ),
      );
}
