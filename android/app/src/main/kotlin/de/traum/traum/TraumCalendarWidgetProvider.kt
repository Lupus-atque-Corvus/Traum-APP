package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumCalendarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_calendar)
            val nextAppointment = widgetData.getString("nextAppointment", "—") ?: "—"

            views.setTextViewText(R.id.tv_next_appointment, nextAppointment)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
