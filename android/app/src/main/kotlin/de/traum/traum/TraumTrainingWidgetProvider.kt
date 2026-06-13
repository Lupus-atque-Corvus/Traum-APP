package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumTrainingWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Training"
    override val accentHex = "#5B6CF9"
    override val route = "/training"
    override val slots = listOf(
        OverviewSlot("Nächstes", "training.nextWorkout"),
        OverviewSlot("Volumen", "training.weeklyVolume"),
        OverviewSlot("Streak", "training.streak"),
    )
}
