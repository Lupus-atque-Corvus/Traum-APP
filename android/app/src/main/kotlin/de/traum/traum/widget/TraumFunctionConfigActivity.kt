package de.traum.traum.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView
import de.traum.traum.R
import es.antonborri.home_widget.HomeWidgetPlugin

class TraumFunctionConfigActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        setContentView(R.layout.widget_function_config)
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) { finish(); return }

        val defs = WidgetCatalog.functions
        val labels = defs.map { "${it.groupLabel} · ${it.title}" }
        val list = findViewById<ListView>(R.id.lv_functions)
        list.adapter = ArrayAdapter(this, R.layout.widget_function_config_item, R.id.tv_item, labels)
        list.setOnItemClickListener { _, _, pos, _ ->
            val key = defs[pos].key
            getSharedPreferences(FUNCTION_PREFS, Context.MODE_PRIVATE)
                .edit().putString("widget_$appWidgetId", key).apply()
            val mgr = AppWidgetManager.getInstance(this)
            TraumFunctionWidgetProvider().onUpdate(
                this, mgr, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(this)
            )
            setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId))
            finish()
        }
    }
}
