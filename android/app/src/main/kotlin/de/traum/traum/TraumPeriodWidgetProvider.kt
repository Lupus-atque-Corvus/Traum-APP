package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumPeriodWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_period)
            val periodDaysLabel = widgetData.getString("periodDaysLabel", "—") ?: "—"

            views.setTextViewText(R.id.tv_period_days, periodDaysLabel)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
