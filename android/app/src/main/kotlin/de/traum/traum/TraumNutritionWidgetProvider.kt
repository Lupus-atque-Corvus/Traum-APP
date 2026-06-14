package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumNutritionWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Ernährung"
    override val accentHex = "#3DD68C"
    override val route = "/nutrition"
    override val group = "nutrition"
    override val slots = listOf(
        OverviewSlot("Kalorien", "nutrition.kcal", " kcal", goalKey = "nutrition.kcalGoal"),
        OverviewSlot("Protein", "nutrition.protein", " g"),
        OverviewSlot("Wasser", "nutrition.waterMl", " ml"),
        OverviewSlot("Mahlzeit", "nutrition.lastMeal"),
    )
}
