import 'package:flutter/material.dart';

class TraumColors {
  TraumColors._();

  // Hintergründe
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF22223A);
  static const Color bottomNav = Color(0xFF12121F);
  static const Color surfaceElevated = Color(0xFF1E1E32);

  // Budget-Spec-spezifische Flächen (PIXELGENAUE_SPEZIFIKATION §0.1)
  static const Color heroGradA = Color(0xFF1D1D33);   // Hero-Verlauf oben (155°)
  static const Color heroGradB = Color(0xFF181828);   // Hero-Verlauf unten
  static const Color heroInner = Color(0xFF15152A);   // Mini-Kacheln in Hero
  static const Color sheetBg = Color(0xFF161628);      // Add-Sheet-Hintergrund
  static const Color numKey = Color(0xFF1F1F36);       // Numpad-Ziffern
  static const Color surfaceHover = Color(0xFF2A2A45); // Numpad Hover
  static const Color dimBar = Color(0xFF3A3A52);       // Grabber-Handle im Sheet

  // Text
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onBackgroundMuted = Color(0xFF8888AA);
  static const Color onBackgroundSubtle = Color(0xFF555577);
  static const Color textBright = Color(0xFFCFCFE0);   // helle Sekundärtexte (Status-Bar, Prognose)

  // Akzente Warm
  static const Color coralOrange = Color(0xFFFF6B3D);
  static const Color peachOrange = Color(0xFFFFAA55);
  static const Color coralDim = Color(0x33FF6B3D);

  // Akzente Cool
  static const Color cyanBlue = Color(0xFF00D4D4);
  static const Color turquoiseBlue = Color(0xFF0099BB);
  static const Color cyanDim = Color(0x3300D4D4);

  // Komplementäre Akzente
  static const Color lavender = Color(0xFF9B8EC4);
  static const Color lavenderDim = Color(0x339B8EC4);
  static const Color mintGreen = Color(0xFF3DD68C);
  static const Color mintGreenDim = Color(0x333DD68C);
  static const Color amberGold = Color(0xFFF5A623);
  static const Color amberGoldDim = Color(0x33F5A623);
  static const Color indigoBlue = Color(0xFF5B6CF9);
  static const Color indigoBlueDim = Color(0x335B6CF9);
  static const Color roseRed = Color(0xFFF43F5E);
  static const Color roseRedDim = Color(0x33F43F5E);

  // Status
  static const Color success = mintGreen;
  static const Color warning = amberGold;
  static const Color error = roseRed;
  static const Color overbudget = roseRed;

  // Zyklus-Spezifisch
  static const Color periodRose = Color(0xFFFF8FAB);
  static const Color ovulationCyan = Color(0xFF00C9C8);
  static const Color fertileCyan = Color(0xFF0093AB);

  // Gradienten
  static const LinearGradient gradientWarm = LinearGradient(
    colors: [coralOrange, peachOrange],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientCool = LinearGradient(
    colors: [cyanBlue, turquoiseBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientAccent = LinearGradient(
    colors: [coralOrange, cyanBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientBudgetLine = LinearGradient(
    colors: [amberGold, coralOrange],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientPlanning = LinearGradient(
    colors: [lavender, indigoBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientNutrition = LinearGradient(
    colors: [mintGreen, cyanBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientMedical = LinearGradient(
    colors: [roseRed, lavender],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientSupplements = LinearGradient(
    colors: [indigoBlue, cyanBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cycleGradient = LinearGradient(
    colors: [periodRose, ovulationCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientHero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [heroGradA, heroGradB],
  );

  // Modul-Farben
  static Color moduleColor(String module) {
    switch (module) {
      case 'home':
      case 'training':
        return coralOrange;
      case 'health':
        return cyanBlue;
      case 'nutrition':
        return mintGreen;
      case 'substances':
        return indigoBlue;
      case 'planning':
        return lavender;
      case 'diary':
        return peachOrange;
      case 'graffitiMap':
        return cyanBlue;
      case 'notes':
        return lavender;
      case 'abstinence':
        return roseRed;
      case 'budget':
        return amberGold;
      case 'period':
      case 'periodTracking':
        return periodRose;
      case 'profile':
        return lavender;
      case 'settings':
        return onBackgroundMuted;
      default:
        return coralOrange;
    }
  }
}
