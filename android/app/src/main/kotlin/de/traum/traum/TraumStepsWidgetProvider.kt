package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumStepsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_steps)
            val steps = widgetData.getString("steps", "0") ?: "0"
            val stepsGoal = widgetData.getString("stepsGoal", "10000") ?: "10000"

            val stepsInt = steps.toIntOrNull() ?: 0
            val goalInt = stepsGoal.toIntOrNull()?.takeIf { it > 0 } ?: 10000
            val progress = ((stepsInt.toFloat() / goalInt.toFloat()) * 100).toInt().coerceIn(0, 100)

            views.setTextViewText(R.id.tv_steps, steps)
            views.setTextViewText(R.id.tv_steps_goal, "Ziel: $stepsGoal")
            views.setProgressBar(R.id.pb_steps, 100, progress, false)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
