package de.traum.traum.workers

import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters

class BudgetAlertWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val notification = NotificationCompat.Builder(applicationContext, "budget_channel")
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle("TRAUM — Budget")
            .setContentText("Achtung: Du näherst dich deinem Budgetlimit")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(applicationContext).notify(1008, notification)
        return Result.success()
    }
}
