package de.traum.traum

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TraumOverviewWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_template_overview)
            val steps = widgetData.getString("health.steps", "0") ?: "0"
            val kcal = widgetData.getString("nutrition.kcal", "0") ?: "0"
            val water = widgetData.getString("nutrition.waterMl", "0") ?: "0"
            val todo = widgetData.getString("planning.nextTodo", "") ?: ""

            views.setTextViewText(R.id.tv_primary, steps)
            views.setTextViewText(R.id.tv_kcal, "$kcal kcal")
            views.setTextViewText(R.id.tv_water, "$water ml")
            views.setTextViewText(R.id.tv_todo, todo)

            applyBucket(appWidgetManager, id, views)

            val intent = Intent(context, MainActivity::class.java).apply {
                putExtra("widget_route", "/home")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pi = PendingIntent.getActivity(
                context, id, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_template_overview)
        applyBucket(appWidgetManager, appWidgetId, views)
        appWidgetManager.partiallyUpdateAppWidget(appWidgetId, views)
    }

    /** Show extra rows depending on available size. */
    private fun applyBucket(
        appWidgetManager: AppWidgetManager,
        id: Int,
        views: RemoteViews
    ) {
        val opts = appWidgetManager.getAppWidgetOptions(id)
        val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val medium = minH >= 110 || minW >= 250
        val large = minH >= 200
        views.setViewVisibility(R.id.row_secondary, if (medium) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.tv_todo, if (large) View.VISIBLE else View.GONE)
    }
}
