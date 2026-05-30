package de.traum.traum

import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "traum/calendar"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCalendars" -> {
                    try {
                        val calendars = mutableListOf<Map<String, Any?>>()
                        val projection = arrayOf(
                            CalendarContract.Calendars._ID,
                            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                            CalendarContract.Calendars.ACCOUNT_NAME,
                            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                            CalendarContract.Calendars.CALENDAR_COLOR,
                        )
                        val cursor = contentResolver.query(
                            CalendarContract.Calendars.CONTENT_URI,
                            projection, null, null, null
                        )
                        cursor?.use {
                            while (it.moveToNext()) {
                                val id = it.getLong(
                                    it.getColumnIndexOrThrow(CalendarContract.Calendars._ID)
                                ).toString()
                                val name = it.getString(
                                    it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
                                )
                                val accountName = it.getString(
                                    it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME)
                                )
                                val accessLevel = it.getInt(
                                    it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL)
                                )
                                val color = it.getInt(
                                    it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR)
                                )
                                // Only include calendars with at least read-write access
                                if (accessLevel >= 300) {
                                    calendars.add(
                                        mapOf(
                                            "id" to id,
                                            "name" to name,
                                            "accountName" to accountName,
                                            "color" to color,
                                        )
                                    )
                                }
                            }
                        }
                        result.success(calendars)
                    } catch (e: Exception) {
                        result.error("CALENDAR_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
