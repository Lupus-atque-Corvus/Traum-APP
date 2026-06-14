package de.traum.traum

import de.traum.traum.widget.BaseOverviewWidgetProvider
import de.traum.traum.widget.OverviewSlot

class TraumBudgetWidgetProvider : BaseOverviewWidgetProvider() {
    override val title = "Budget"
    override val accentHex = "#00D4D4"
    override val route = "/budget"
    override val slots = listOf(
        OverviewSlot("Saldo", "budget.balanceMonth", " €"),
        OverviewSlot("Ausgaben", "budget.spent", " €"),
        OverviewSlot("Einnahmen", "budget.income", " €"),
        OverviewSlot("Top", "budget.topCategory"),
    )
}
