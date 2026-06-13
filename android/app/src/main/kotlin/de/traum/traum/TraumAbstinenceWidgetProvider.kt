package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumAbstinenceWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Abstinenz"
    override val accentHex = "#FFAA55"
    override val route = "/abstinence"
    override val slots = listOf(
        OverviewSlot("Titel", "abstinence.title"),
        OverviewSlot("Dauer", "abstinence.duration"),
        OverviewSlot("Gespart", "abstinence.moneySaved", " €"),
    )
}
