package de.traum.traum.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import de.traum.traum.MainActivity
import de.traum.traum.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/** Ein darzustellender Wert: Label + Group-Store-Key (+ optionaler Suffix wie " kcal"). */
data class OverviewSlot(val label: String, val valueKey: String, val suffix: String = "")

/**
 * Generische Basis für alle benannten Tab-Übersichts-Widgets.
 * Subklassen liefern nur Titel, Akzentfarbe, Route und bis zu 4 Slots.
 */
abstract class BaseOverviewWidgetProvider : HomeWidgetProvider() {
    abstract val title: String
    abstract val accentHex: String
    abstract val route: String
    /** Slot 0 = Primärzahl, 1..3 = Sekundär-Zellen. */
    abstract val slots: List<OverviewSlot>

    private fun buildViews(
        context: Context,
        appWidgetManager: AppWidgetManager,
        id: Int,
        widgetData: SharedPreferences
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_template_overview)
        val accent = runCatching { Color.parseColor(accentHex) }.getOrDefault(Color.WHITE)

        views.setTextViewText(R.id.tv_title, title.uppercase())
        views.setTextColor(R.id.tv_title, accent)

        fun read(slot: OverviewSlot): String {
            val v = widgetData.getString(slot.valueKey, "—") ?: "—"
            val shown = if (v.isBlank()) "—" else v
            return shown + slot.suffix
        }

        val slot0 = slots.getOrNull(0)
        val primaryEmpty = slot0 == null ||
            (widgetData.getString(slot0.valueKey, null)?.isBlank() != false)

        if (primaryEmpty) {
            views.setTextViewText(R.id.tv_primary, "—")
            views.setTextViewText(R.id.tv_primary_label, "Noch keine Daten")
            views.setViewVisibility(R.id.row_secondary, View.GONE)
            views.setViewVisibility(R.id.row_tertiary, View.GONE)
            views.setViewVisibility(R.id.tv_footer, View.GONE)
        } else {
            slot0?.let {
                views.setTextViewText(R.id.tv_primary, read(it))
                views.setTextViewText(R.id.tv_primary_label, it.label)
            }
            slots.getOrNull(1)?.let {
                views.setTextViewText(R.id.tv_s1_value, read(it)); views.setTextViewText(R.id.tv_s1_label, it.label)
            }
            slots.getOrNull(2)?.let {
                views.setTextViewText(R.id.tv_s2_value, read(it)); views.setTextViewText(R.id.tv_s2_label, it.label)
            }
            slots.getOrNull(3)?.let {
                views.setTextViewText(R.id.tv_s3_value, read(it)); views.setTextViewText(R.id.tv_s3_label, it.label)
            }
            applyBucket(appWidgetManager, id, views)
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra("widget_route", route)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pi = PendingIntent.getActivity(
            context, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pi)

        return views
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id, widgetData))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        appWidgetManager.updateAppWidget(
            appWidgetId,
            buildViews(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
        )
    }

    private fun applyBucket(appWidgetManager: AppWidgetManager, id: Int, views: RemoteViews) {
        val opts = appWidgetManager.getAppWidgetOptions(id)
        val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val medium = minH >= 110 || minW >= 250
        val large = minH >= 200
        views.setViewVisibility(R.id.row_secondary, if (medium && slots.size > 1) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.row_tertiary, if (large && slots.size > 3) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.tv_footer, View.GONE)
    }
}
