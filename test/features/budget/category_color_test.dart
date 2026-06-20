// test/features/budget/category_color_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/budget_category_colors.dart';

void main() {
  BudgetCategory cat(int? color) => BudgetCategory(
      id: 1, name: 'x', emoji: null, monthlyLimit: null, color: color, isExpense: true);
  test('stored colour wins, else palette by index', () {
    expect(colorForCategory(cat(0xFF112233), 0), const Color(0xFF112233));
    expect(colorForCategory(cat(null), 1), kBudgetCategoryColors[1]);
  });
}
