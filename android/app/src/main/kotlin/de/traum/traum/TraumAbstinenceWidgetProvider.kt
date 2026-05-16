package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumAbstinenceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_abstinence)
            val abstinenceTitle = widgetData.getString("abstinenceTitle", "—") ?: "—"
            val abstinenceDuration = widgetData.getString("abstinenceDuration", "—") ?: "—"

            views.setTextViewText(R.id.tv_abstinence_title, abstinenceTitle)
            views.setTextViewText(R.id.tv_abstinence_duration, abstinenceDuration)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
