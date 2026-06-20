import 'package:flutter/material.dart';

import '../../data/database/traum_database.dart';

const List<Color> kBudgetCategoryColors = [
  Color(0xFFFF6B3D), // coralOrange — Wohnen
  Color(0xFF3DD68C), // mintGreen   — Lebensmittel
  Color(0xFF00D4D4), // cyanBlue    — Transport
  Color(0xFF9B8EC4), // lavender    — Freizeit
  Color(0xFF8888AA), // muted       — Sonstiges
  Color(0xFFF5A623), // amberGold   — Weitere
  Color(0xFF5B6CF9), // indigoBlue  — Weitere
  Color(0xFFF43F5E), // roseRed     — Weitere
];

Color categoryColor(int index) =>
    kBudgetCategoryColors[index % kBudgetCategoryColors.length];

Color colorForCategory(BudgetCategory cat, int index) =>
    cat.color != null ? Color(cat.color!) : categoryColor(index);
