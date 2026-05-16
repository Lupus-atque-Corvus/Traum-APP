package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumHealthWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_health)
            val sleepHours = widgetData.getString("sleepHours", "—")
            val heartRate = widgetData.getString("heartRate", "—")
            val mood = widgetData.getString("mood", "—")

            views.setTextViewText(R.id.tv_sleep, "$sleepHours h Schlaf")
            views.setTextViewText(R.id.tv_heart_rate, "$heartRate bpm")
            views.setTextViewText(R.id.tv_mood, "Stimmung: $mood")

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
