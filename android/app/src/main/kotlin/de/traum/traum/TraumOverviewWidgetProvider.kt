package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumOverviewWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Übersicht"
    override val accentHex = "#FF6B3D"
    override val route = "/home"
    override val group = "general"
    override val slots = listOf(
        OverviewSlot("Schritte", "health.steps", goalKey = "health.stepsGoal"),
        OverviewSlot("Kalorien", "nutrition.kcal", " kcal"),
        OverviewSlot("Wasser", "nutrition.waterMl", " ml"),
        OverviewSlot("Aufgabe", "planning.nextTodo"),
    )
}
