package de.traum.traum.workers

import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters

class WaterReminderWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val notification = NotificationCompat.Builder(applicationContext, "water_channel")
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle("TRAUM — Wasser trinken")
            .setContentText("Denk daran, ausreichend Wasser zu trinken!")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(applicationContext).notify(1004, notification)
        return Result.success()
    }
}
