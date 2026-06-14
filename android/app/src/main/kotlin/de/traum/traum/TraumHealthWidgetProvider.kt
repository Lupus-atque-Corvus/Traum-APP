package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumHealthWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Gesundheit"
    override val accentHex = "#F43F5E"
    override val route = "/health"
    override val group = "health"
    override val slots = listOf(
        OverviewSlot("Score", "health.score"),
        OverviewSlot("Schlaf", "health.sleepHours", " h"),
        OverviewSlot("Puls", "health.heartRate", " bpm"),
        OverviewSlot("Aktiv", "health.activeMinutes", " min"),
    )
}
