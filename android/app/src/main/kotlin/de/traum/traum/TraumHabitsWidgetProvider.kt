package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumHabitsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_habits)
            val habitsCompleted = widgetData.getString("habitsCompleted", "0") ?: "0"
            val habitsTotal = widgetData.getString("habitsTotal", "0") ?: "0"

            val completed = habitsCompleted.toIntOrNull() ?: 0
            val total = habitsTotal.toIntOrNull()?.takeIf { it > 0 } ?: 1
            val progress = ((completed.toFloat() / total.toFloat()) * 100).toInt().coerceIn(0, 100)

            views.setTextViewText(R.id.tv_habits, "$habitsCompleted / $habitsTotal Gewohnheiten")
            views.setProgressBar(R.id.pb_habits, 100, progress, false)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
