package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumSubstancesWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Mittel"
    override val accentHex = "#0099BB"
    override val route = "/substances"
    override val group = "substances"
    override val slots = listOf(
        OverviewSlot("Zuletzt", "substances.lastIntake"),
        OverviewSlot("Heute", "substances.takenToday"),
    )
}
