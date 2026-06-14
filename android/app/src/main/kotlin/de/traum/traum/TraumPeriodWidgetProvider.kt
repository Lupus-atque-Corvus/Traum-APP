package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumPeriodWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Zyklus"
    override val accentHex = "#FF8FAB"
    override val route = "/period"
    override val group = "period"
    override val slots = listOf(
        OverviewSlot("Zyklustag", "period.cycleDay"),
        OverviewSlot("Phase", "period.phase"),
        OverviewSlot("Nächste", "period.nextDays", " T"),
    )
}
