package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumMedicationWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_medication)
            val medsTaken = widgetData.getString("medsTaken", "0") ?: "0"
            val medsTotal = widgetData.getString("medsTotal", "0") ?: "0"

            val taken = medsTaken.toIntOrNull() ?: 0
            val total = medsTotal.toIntOrNull()?.takeIf { it > 0 } ?: 1
            val progress = ((taken.toFloat() / total.toFloat()) * 100).toInt().coerceIn(0, 100)

            views.setTextViewText(R.id.tv_meds, "$medsTaken / $medsTotal Medikamente")
            views.setProgressBar(R.id.pb_meds, 100, progress, false)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
