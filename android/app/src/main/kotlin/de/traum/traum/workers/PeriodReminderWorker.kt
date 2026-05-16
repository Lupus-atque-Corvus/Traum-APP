package de.traum.traum.workers

import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters

class PeriodReminderWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val notification = NotificationCompat.Builder(applicationContext, "period_channel")
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle("TRAUM — Zyklus")
            .setContentText("Deine Periode könnte bald beginnen")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(applicationContext).notify(1007, notification)
        return Result.success()
    }
}
