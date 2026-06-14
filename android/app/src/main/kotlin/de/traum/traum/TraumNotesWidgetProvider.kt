package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumNotesWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Notizen"
    override val accentHex = "#9B8EC4"
    override val route = "/notes"
    override val slots = listOf(
        OverviewSlot("Notizen", "notes.count"),
        OverviewSlot("Letzte", "notes.lastNote"),
    )
}
