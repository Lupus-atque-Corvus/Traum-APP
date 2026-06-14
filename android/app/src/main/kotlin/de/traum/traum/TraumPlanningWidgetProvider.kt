package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumPlanningWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Planung"
    override val accentHex = "#F5A623"
    override val route = "/planning"
    override val group = "planning"
    override val slots = listOf(
        OverviewSlot("Offen", "planning.openTodos"),
        OverviewSlot("Termin", "planning.nextAppointment"),
        OverviewSlot("Habits", "planning.habitsDone"),
        OverviewSlot("Medis", "planning.medsDone"),
    )
}
