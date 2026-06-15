package de.traum.traum.widget

/** Parser für die im Group-Store kodierten Serien-Strings. */
object WidgetSeries {
    /** "4200,5100,0" -> [4200.0, 5100.0, 0.0]; leer/fehlerhaft -> []. */
    fun numbers(csv: String?): List<Double> {
        if (csv.isNullOrBlank()) return emptyList()
        return csv.split(",").mapNotNull { it.trim().toDoubleOrNull() }
    }

    /** "Apfel;Reis" -> ["Apfel","Reis"]; leer -> []. */
    fun labels(s: String?): List<String> {
        if (s.isNullOrBlank()) return emptyList()
        return s.split(";").map { it.trim() }.filter { it.isNotEmpty() }
    }
}
