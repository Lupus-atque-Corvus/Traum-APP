package de.traum.traum

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumNutritionWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_nutrition)
            val kcal = widgetData.getString("kcal", "0")
            val kcalGoal = widgetData.getString("kcalGoal", "2000")
            val protein = widgetData.getString("protein", "0")
            val water = widgetData.getString("waterMl", "0")

            views.setTextViewText(R.id.tv_kcal, "$kcal / $kcalGoal kcal")
            views.setTextViewText(R.id.tv_protein, "$protein g Protein")
            views.setTextViewText(R.id.tv_water, "$water ml Wasser")

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
