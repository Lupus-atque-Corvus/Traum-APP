package de.traum.traum.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.widget.RemoteViews
import de.traum.traum.MainActivity
import de.traum.traum.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/** SharedPreferences file mapping appWidgetId -> functionKey. */
const val FUNCTION_PREFS = "de.traum.widget.function"

class TraumFunctionWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val cfg = context.getSharedPreferences(FUNCTION_PREFS, Context.MODE_PRIVATE)
        appWidgetIds.forEach { id ->
            val key = cfg.getString("widget_$id", null)
            val def = key?.let { WidgetCatalog.byKey(it) }
            val views = if (def == null) emptyViews(context) else renderFunction(context, def, widgetData)
            val route = def?.route ?: "/home"
            val intent = Intent(context, MainActivity::class.java).apply {
                putExtra("widget_route", route)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(
                    context, id, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
    }

    private fun emptyViews(context: Context): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_template_stat).apply {
            setTextViewText(R.id.tv_title, "TRAUM")
            setTextViewText(R.id.tv_value, "—")
            setTextViewText(R.id.tv_label, "Funktion wählen")
        }

    /** Setzt Gradient-Hintergrund + getöntes Header-Icon + Titel (Icon/Titel auf Layouts ohne diese Views: no-op). */
    private fun header(views: RemoteViews, def: WidgetCatalogDef, accent: Int) {
        views.setInt(R.id.widget_root, "setBackgroundResource", WidgetAssets.bgRes(def.group))
        views.setTextViewText(R.id.tv_title, def.title.uppercase())
        views.setTextColor(R.id.tv_title, accent)
        views.setImageViewResource(R.id.iv_icon, WidgetAssets.iconRes(def.group))
        views.setInt(R.id.iv_icon, "setColorFilter", accent)
    }

    private fun renderFunction(context: Context, def: WidgetCatalogDef, data: SharedPreferences): RemoteViews {
        val accent = runCatching { Color.parseColor(def.accentHex) }.getOrDefault(Color.WHITE)
        fun s(key: String) = (data.getString(key, "—") ?: "—").ifBlank { "—" }
        fun raw(key: String) = data.getString(key, "") ?: ""
        val slot0 = def.slots.getOrNull(0)
        val slot1 = def.slots.getOrNull(1)
        return when (def.template) {
            "progress" -> RemoteViews(context.packageName, R.layout.widget_template_progress).apply {
                header(this, def, accent)
                setTextViewText(R.id.tv_value, slot0?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_label, slot0?.label ?: "")
                val v = slot0?.let { s(it.valueKey).toDoubleOrNull() } ?: 0.0
                val g = slot0?.goalKey?.let { s(it).toDoubleOrNull() } ?: 0.0
                setProgressBar(R.id.pb_progress, 100, if (g > 0) ((v / g) * 100).toInt().coerceIn(0, 100) else 0, false)
            }
            "dualStat" -> RemoteViews(context.packageName, R.layout.widget_template_dualstat).apply {
                header(this, def, accent)
                setTextViewText(R.id.tv_a_value, slot0?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_a_label, slot0?.label ?: "")
                setTextViewText(R.id.tv_b_value, slot1?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_b_label, slot1?.label ?: "")
            }
            "list" -> RemoteViews(context.packageName, R.layout.widget_template_list).apply {
                header(this, def, accent)
                setTextViewText(R.id.tv_row1, slot0?.let { s(it.valueKey) } ?: "—")
            }
            "ring" -> RemoteViews(context.packageName, R.layout.widget_template_graphic).apply {
                header(this, def, accent)
                val v = slot0?.let { s(it.valueKey).toDoubleOrNull() } ?: 0.0
                val g = slot0?.goalKey?.let { s(it).toDoubleOrNull() } ?: 0.0
                setImageViewBitmap(R.id.iv_graphic, WidgetGraphics.progressRing(v, g, accent, 220))
                setTextViewText(R.id.tv_caption, slot0?.label ?: "")
            }
            "ringTrio" -> RemoteViews(context.packageName, R.layout.widget_template_graphic).apply {
                header(this, def, accent)
                val rings = def.slots.take(3).map {
                    (s(it.valueKey).toDoubleOrNull() ?: 0.0) to (it.goalKey?.let { g -> s(g).toDoubleOrNull() } ?: 100.0)
                }
                val cols = listOf(accent, 0xFF3DD68C.toInt(), 0xFF64B5F6.toInt())
                setImageViewBitmap(R.id.iv_graphic, WidgetGraphics.ringTrio(rings, cols, 240))
                setTextViewText(R.id.tv_caption, def.title)
            }
            "barChart" -> RemoteViews(context.packageName, R.layout.widget_template_graphic).apply {
                header(this, def, accent)
                setImageViewBitmap(R.id.iv_graphic, WidgetGraphics.barChart(WidgetSeries.numbers(raw(slot0?.valueKey ?: "")), accent, 360, 200))
                setTextViewText(R.id.tv_caption, slot0?.label ?: "")
            }
            "sparkline" -> RemoteViews(context.packageName, R.layout.widget_template_graphic).apply {
                header(this, def, accent)
                setImageViewBitmap(R.id.iv_graphic, WidgetGraphics.sparkline(WidgetSeries.numbers(raw(slot0?.valueKey ?: "")), accent, 360, 160))
                setTextViewText(R.id.tv_caption, slot0?.label ?: "")
            }
            "donut" -> RemoteViews(context.packageName, R.layout.widget_template_graphic).apply {
                header(this, def, accent)
                val nums = WidgetSeries.numbers(raw(slot0?.valueKey ?: ""))
                val cols = listOf(0xFF5B6CF9.toInt(), 0xFFF5A623.toInt(), 0xFFF43F5E.toInt())
                setImageViewBitmap(R.id.iv_graphic, WidgetGraphics.donut(nums.mapIndexed { i, v -> v to cols.getOrElse(i) { accent } }, 220))
                setTextViewText(R.id.tv_caption, slot0?.label ?: "")
            }
            "dashboard" -> RemoteViews(context.packageName, R.layout.widget_template_dashboard).apply {
                header(this, def, accent)
                val cellIds = listOf(
                    R.id.cell1_value to R.id.cell1_label,
                    R.id.cell2_value to R.id.cell2_label,
                    R.id.cell3_value to R.id.cell3_label,
                    R.id.cell4_value to R.id.cell4_label,
                )
                def.slots.take(4).forEachIndexed { i, slot ->
                    setTextViewText(cellIds[i].first, s(slot.valueKey)); setTextViewText(cellIds[i].second, slot.label)
                }
            }
            "motivation" -> RemoteViews(context.packageName, R.layout.widget_template_motivation).apply {
                header(this, def, accent)
                setImageViewResource(R.id.iv_graphic, WidgetAssets.iconRes(def.group)); setInt(R.id.iv_graphic, "setColorFilter", accent)
                setTextViewText(R.id.tv_value, slot0?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_caption, def.title)
            }
            else -> RemoteViews(context.packageName, R.layout.widget_template_stat).apply {
                header(this, def, accent)
                setTextViewText(R.id.tv_value, slot0?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_label, slot0?.label ?: "")
            }
        }
    }
}
