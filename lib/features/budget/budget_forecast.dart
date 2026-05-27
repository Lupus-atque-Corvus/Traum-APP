class BudgetForecast {
  /// Returns forecasted end-of-month balance.
  /// Returns null if less than 5 days of data.
  static double? forecastEndOfMonth({
    required double currentBalance,
    required int dayOfMonth,
    required int daysInMonth,
  }) {
    if (dayOfMonth < 5) return null;
    final dailyRate = currentBalance / dayOfMonth;
    final remainingDays = daysInMonth - dayOfMonth;
    return currentBalance + (dailyRate * remainingDays);
  }

  /// Average daily spending from a list of daily expense totals.
  static double dailySpendingRate(List<double> last7DaysExpenses) {
    if (last7DaysExpenses.isEmpty) return 0;
    return last7DaysExpenses.reduce((a, b) => a + b) / last7DaysExpenses.length;
  }
}
