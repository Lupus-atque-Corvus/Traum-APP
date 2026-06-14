package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumMapWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Karte"
    override val accentHex = "#3DD68C"
    override val route = "/graffitimap"
    override val group = "map"
    override val slots = listOf(
        OverviewSlot("Orte", "map.placesCount"),
        OverviewSlot("Foto", "map.lastPhoto"),
    )
}
