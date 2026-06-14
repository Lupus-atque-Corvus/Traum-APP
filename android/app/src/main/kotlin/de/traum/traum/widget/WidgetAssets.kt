package de.traum.traum.widget

import de.traum.traum.R

/** Mappt group-Slug → Gradient-Drawable, und key/group → Icon-Drawable. */
object WidgetAssets {
    fun bgRes(group: String): Int = when (group) {
        "general" -> R.drawable.widget_bg_general
        "health" -> R.drawable.widget_bg_health
        "nutrition" -> R.drawable.widget_bg_nutrition
        "training" -> R.drawable.widget_bg_training
        "planning" -> R.drawable.widget_bg_planning
        "budget" -> R.drawable.widget_bg_budget
        "diary" -> R.drawable.widget_bg_diary
        "abstinence" -> R.drawable.widget_bg_abstinence
        "substances" -> R.drawable.widget_bg_substances
        "period" -> R.drawable.widget_bg_period
        "notes" -> R.drawable.widget_bg_notes
        "map" -> R.drawable.widget_bg_map
        else -> R.drawable.widget_bg
    }

    fun iconRes(group: String): Int = when (group) {
        "health" -> R.drawable.ic_w_heart
        "nutrition" -> R.drawable.ic_w_kcal
        "training" -> R.drawable.ic_w_training
        "planning" -> R.drawable.ic_w_planning
        "budget" -> R.drawable.ic_w_budget
        "diary" -> R.drawable.ic_w_diary
        "abstinence" -> R.drawable.ic_w_abstinence
        "substances" -> R.drawable.ic_w_substances
        "period" -> R.drawable.ic_w_period
        "notes" -> R.drawable.ic_w_notes
        "map" -> R.drawable.ic_w_map
        else -> R.drawable.ic_w_overview
    }
}
