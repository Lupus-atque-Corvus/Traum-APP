package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumOverviewWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_overview)
            val steps = widgetData.getString("steps", "0")
            val stepsGoal = widgetData.getString("stepsGoal", "10000")
            val kcal = widgetData.getString("kcal", "0")
            val water = widgetData.getString("waterMl", "0")

            views.setTextViewText(R.id.tv_steps, "$steps Schritte")
            views.setTextViewText(R.id.tv_kcal, "$kcal kcal")
            views.setTextViewText(R.id.tv_water, "$water ml Wasser")

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
