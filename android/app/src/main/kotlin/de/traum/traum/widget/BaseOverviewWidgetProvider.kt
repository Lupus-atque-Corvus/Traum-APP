package de.traum.traum.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import de.traum.traum.MainActivity
import de.traum.traum.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/** Ein darzustellender Wert: Label + Group-Store-Key (+ optionaler Suffix wie " kcal" + optionales Ziel für Ring). */
data class OverviewSlot(val label: String, val valueKey: String, val suffix: String = "", val goalKey: String? = null)

/** Größen-Bucket für responsives Layout (Sichtbarkeit der Sekundär-/Tertiär-Zeilen). */
private enum class Bucket { COMPACT, MEDIUM, LARGE }

/**
 * Generische Basis für alle benannten Tab-Übersichts-Widgets.
 * Subklassen liefern nur Titel, Akzentfarbe, Route und bis zu 4 Slots.
 */
abstract class BaseOverviewWidgetProvider : HomeWidgetProvider() {
    abstract val title: String
    abstract val accentHex: String
    abstract val route: String
    /** Group-Slug für Gradient-Hintergrund + Header-Icon (z. B. "health"). */
    abstract val group: String
    /** Slot 0 = Primärzahl, 1..3 = Sekundär-Zellen. */
    abstract val slots: List<OverviewSlot>

    private fun buildViews(
        context: Context,
        id: Int,
        widgetData: SharedPreferences,
        bucket: Bucket
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_template_overview)
        val accent = runCatching { Color.parseColor(accentHex) }.getOrDefault(Color.WHITE)

        views.setInt(R.id.widget_root, "setBackgroundResource", WidgetAssets.bgRes(group))
        views.setImageViewResource(R.id.iv_icon, WidgetAssets.iconRes(group))
        views.setInt(R.id.iv_icon, "setColorFilter", accent)

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
            views.setViewVisibility(R.id.iv_graphic, View.GONE)
            views.setViewVisibility(R.id.row_secondary, View.GONE)
            views.setViewVisibility(R.id.row_tertiary, View.GONE)
            views.setViewVisibility(R.id.tv_footer, View.GONE)
        } else {
            slot0?.let {
                views.setTextViewText(R.id.tv_primary, read(it))
                views.setTextViewText(R.id.tv_primary_label, it.label)
            }
            val goalKey = slot0?.goalKey
            val v = slot0?.let { widgetData.getString(it.valueKey, "0")?.toDoubleOrNull() } ?: 0.0
            val g = goalKey?.let { widgetData.getString(it, "0")?.toDoubleOrNull() } ?: 0.0
            if (goalKey != null && g > 0) {
                views.setImageViewBitmap(R.id.iv_graphic, WidgetGraphics.progressRing(v, g, accent, 140))
                views.setViewVisibility(R.id.iv_graphic, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.iv_graphic, View.GONE)
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
            val medium = bucket != Bucket.COMPACT
            val large = bucket == Bucket.LARGE
            views.setViewVisibility(R.id.row_secondary, if (medium && slots.size > 1) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.row_tertiary, if (large && slots.size > 3) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.tv_footer, View.GONE)
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

    /** Liefert für API≥31 ein größen-responsives RemoteViews, sonst Bucket aus den Optionen. */
    private fun buildSizedViews(
        context: Context,
        appWidgetManager: AppWidgetManager,
        id: Int,
        widgetData: SharedPreferences
    ): RemoteViews {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val mapping = mapOf(
                SizeF(120f, 100f) to buildViews(context, id, widgetData, Bucket.COMPACT),
                SizeF(250f, 100f) to buildViews(context, id, widgetData, Bucket.MEDIUM),
                SizeF(250f, 200f) to buildViews(context, id, widgetData, Bucket.LARGE),
            )
            return RemoteViews(mapping)
        }
        return buildViews(context, id, widgetData, bucketFromOptions(appWidgetManager, id))
    }

    private fun bucketFromOptions(appWidgetManager: AppWidgetManager, id: Int): Bucket {
        val opts = appWidgetManager.getAppWidgetOptions(id)
        val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        return when {
            minH >= 200 -> Bucket.LARGE
            minH >= 110 || minW >= 250 -> Bucket.MEDIUM
            else -> Bucket.COMPACT
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, buildSizedViews(context, appWidgetManager, id, widgetData))
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
            buildSizedViews(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
        )
    }
}
