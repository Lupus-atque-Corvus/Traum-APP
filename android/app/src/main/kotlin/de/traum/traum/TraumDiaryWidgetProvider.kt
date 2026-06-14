package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumDiaryWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Tagebuch"
    override val accentHex = "#9B8EC4"
    override val route = "/diary"
    override val slots = listOf(
        OverviewSlot("Streak", "diary.writeStreak"),
        OverviewSlot("Letzter", "diary.lastEntry"),
        OverviewSlot("Monat", "diary.entriesThisMonth"),
    )
}
