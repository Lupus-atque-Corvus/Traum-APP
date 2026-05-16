package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumBudgetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_budget)
            val budgetSpent = widgetData.getString("budgetSpent", "0") ?: "0"
            val budgetLimit = widgetData.getString("budgetLimit", "0") ?: "0"

            val spent = budgetSpent.toFloatOrNull() ?: 0f
            val limit = budgetLimit.toFloatOrNull()?.takeIf { it > 0f } ?: 1f
            val progress = ((spent / limit) * 100).toInt().coerceIn(0, 100)

            views.setTextViewText(R.id.tv_budget_spent, "$budgetSpent €")
            views.setTextViewText(R.id.tv_budget_limit, "von $budgetLimit €")
            views.setProgressBar(R.id.pb_budget, 100, progress, false)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
