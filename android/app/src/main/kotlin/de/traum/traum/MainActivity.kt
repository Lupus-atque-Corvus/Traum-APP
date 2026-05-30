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
                "getEvents" -> {
                    try {
                        val calendarIds = call.argument<List<String>>("calendarIds") ?: emptyList<String>()
                        val startMs = call.argument<Long>("startMs") ?: 0L
                        val endMs = call.argument<Long>("endMs") ?: Long.MAX_VALUE
                        val events = mutableListOf<Map<String, Any?>>()
                        val projection = arrayOf(
                            CalendarContract.Events._ID,
                            CalendarContract.Events.TITLE,
                            CalendarContract.Events.DESCRIPTION,
                            CalendarContract.Events.EVENT_LOCATION,
                            CalendarContract.Events.DTSTART,
                            CalendarContract.Events.DTEND,
                            CalendarContract.Events.ALL_DAY,
                        )
                        val placeholders = calendarIds.joinToString(",") { "?" }
                        val selection = "(${CalendarContract.Events.CALENDAR_ID} IN ($placeholders)) " +
                            "AND (${CalendarContract.Events.DTSTART} >= ?) " +
                            "AND (${CalendarContract.Events.DTSTART} <= ?) " +
                            "AND (${CalendarContract.Events.DELETED} = 0)"
                        val args = (calendarIds + listOf(startMs.toString(), endMs.toString())).toTypedArray()
                        val cursor = contentResolver.query(
                            CalendarContract.Events.CONTENT_URI,
                            projection, selection, args, null
                        )
                        cursor?.use {
                            while (it.moveToNext()) {
                                events.add(mapOf(
                                    "id" to it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events._ID)).toString(),
                                    "title" to it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.TITLE)),
                                    "description" to it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION)),
                                    "location" to it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.EVENT_LOCATION)),
                                    "startMs" to it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTSTART)),
                                    "endMs" to it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTEND)),
                                    "allDay" to (it.getInt(it.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)) == 1),
                                ))
                            }
                        }
                        result.success(events)
                    } catch (e: Exception) {
                        result.error("EVENTS_ERROR", e.message, null)
                    }
                }
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
