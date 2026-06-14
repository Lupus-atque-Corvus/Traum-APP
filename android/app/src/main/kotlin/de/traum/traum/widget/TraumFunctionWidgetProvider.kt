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

    private fun renderFunction(context: Context, def: WidgetCatalogDef, data: SharedPreferences): RemoteViews {
        val accent = runCatching { Color.parseColor(def.accentHex) }.getOrDefault(Color.WHITE)
        fun s(key: String) = (data.getString(key, "—") ?: "—").ifBlank { "—" }
        val slot0 = def.slots.getOrNull(0)
        val slot1 = def.slots.getOrNull(1)
        return when (def.template) {
            "progress" -> RemoteViews(context.packageName, R.layout.widget_template_progress).apply {
                setTextViewText(R.id.tv_title, def.title.uppercase()); setTextColor(R.id.tv_title, accent)
                setTextViewText(R.id.tv_value, slot0?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_label, slot0?.label ?: "")
                val v = slot0?.let { s(it.valueKey).toDoubleOrNull() } ?: 0.0
                val g = slot0?.goalKey?.let { s(it).toDoubleOrNull() } ?: 0.0
                setProgressBar(R.id.pb_progress, 100, if (g > 0) ((v / g) * 100).toInt().coerceIn(0, 100) else 0, false)
            }
            "dualStat" -> RemoteViews(context.packageName, R.layout.widget_template_dualstat).apply {
                setTextViewText(R.id.tv_title, def.title.uppercase()); setTextColor(R.id.tv_title, accent)
                setTextViewText(R.id.tv_a_value, slot0?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_a_label, slot0?.label ?: "")
                setTextViewText(R.id.tv_b_value, slot1?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_b_label, slot1?.label ?: "")
            }
            "list" -> RemoteViews(context.packageName, R.layout.widget_template_list).apply {
                setTextViewText(R.id.tv_title, def.title.uppercase()); setTextColor(R.id.tv_title, accent)
                setTextViewText(R.id.tv_row1, slot0?.let { s(it.valueKey) } ?: "—")
            }
            else -> RemoteViews(context.packageName, R.layout.widget_template_stat).apply {
                setTextViewText(R.id.tv_title, def.title.uppercase()); setTextColor(R.id.tv_title, accent)
                setTextViewText(R.id.tv_value, slot0?.let { s(it.valueKey) } ?: "—")
                setTextViewText(R.id.tv_label, slot0?.label ?: "")
            }
        }
    }
}
