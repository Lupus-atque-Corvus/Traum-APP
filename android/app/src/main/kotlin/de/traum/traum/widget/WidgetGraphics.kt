package de.traum.traum.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import kotlin.math.min

/** Rendert Widget-Grafiken als Bitmaps (für RemoteViews.setImageViewBitmap). */
object WidgetGraphics {
    private const val TRACK = 0xFF333355.toInt()
    private fun cap(px: Int) = px.coerceIn(24, 512)

    /** Fortschritts-Ring mit Prozent-Text in der Mitte. */
    fun progressRing(value: Double, max: Double, accent: Int, sizePx: Int): Bitmap {
        val s = cap(sizePx)
        val bmp = Bitmap.createBitmap(s, s, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val stroke = s * 0.12f
        val pad = stroke / 2f + 2f
        val rect = RectF(pad, pad, s - pad, s - pad)
        val ratio = if (max > 0) (value / max).coerceIn(0.0, 1.0) else 0.0
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE; strokeWidth = stroke; strokeCap = Paint.Cap.ROUND }
        p.color = TRACK; c.drawArc(rect, 0f, 360f, false, p)
        p.color = accent; c.drawArc(rect, -90f, (360.0 * ratio).toFloat(), false, p)
        val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; textAlign = Paint.Align.CENTER; textSize = s * 0.26f; isFakeBoldText = true }
        val pct = "${(ratio * 100).toInt()}%"
        c.drawText(pct, s / 2f, s / 2f - (tp.descent() + tp.ascent()) / 2f, tp)
        return bmp
    }

    /** Drei konzentrische Ringe (Activity-Rings-Stil). values = Liste (wert,max). */
    fun ringTrio(values: List<Pair<Double, Double>>, colors: List<Int>, sizePx: Int): Bitmap {
        val s = cap(sizePx)
        val bmp = Bitmap.createBitmap(s, s, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val stroke = s * 0.10f
        val gap = stroke * 0.45f
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE; strokeWidth = stroke; strokeCap = Paint.Cap.ROUND }
        for (i in 0 until min(3, values.size)) {
            val inset = stroke / 2f + 2f + i * (stroke + gap)
            val rect = RectF(inset, inset, s - inset, s - inset)
            val (v, m) = values[i]
            val ratio = if (m > 0) (v / m).coerceIn(0.0, 1.0) else 0.0
            p.color = TRACK; c.drawArc(rect, 0f, 360f, false, p)
            p.color = colors.getOrElse(i) { Color.WHITE }
            c.drawArc(rect, -90f, (360.0 * ratio).toFloat(), false, p)
        }
        return bmp
    }

    /** Mini-Balkendiagramm (z. B. 7 Tage). */
    fun barChart(values: List<Double>, accent: Int, wPx: Int, hPx: Int): Bitmap {
        val w = cap(wPx); val h = cap(hPx)
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        if (values.isEmpty()) return bmp
        val maxV = (values.maxOrNull() ?: 0.0).coerceAtLeast(1.0)
        val n = values.size
        val gap = w * 0.04f
        val bw = (w - gap * (n + 1)) / n
        val p = Paint(Paint.ANTI_ALIAS_FLAG)
        for (i in values.indices) {
            val bh = (h * 0.92f * (values[i] / maxV)).toFloat().coerceAtLeast(2f)
            val left = gap + i * (bw + gap)
            val top = h - bh
            p.color = if (i == values.lastIndex) accent else (accent and 0x00FFFFFF) or 0x80000000.toInt()
            c.drawRoundRect(RectF(left, top, left + bw, h.toFloat()), bw * 0.3f, bw * 0.3f, p)
        }
        return bmp
    }

    /** Trendlinie (Sparkline). */
    fun sparkline(values: List<Double>, accent: Int, wPx: Int, hPx: Int): Bitmap {
        val w = cap(wPx); val h = cap(hPx)
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        if (values.size < 2) return bmp
        val maxV = values.maxOrNull() ?: 0.0
        val minV = values.minOrNull() ?: 0.0
        val span = (maxV - minV).coerceAtLeast(1e-6)
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE; strokeWidth = h * 0.06f; color = accent; strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND }
        val dx = w.toFloat() / (values.size - 1)
        var prevX = 0f
        var prevY = (h * 0.9f * (1 - (values[0] - minV) / span)).toFloat() + h * 0.05f
        for (i in 1 until values.size) {
            val x = i * dx
            val y = (h * 0.9f * (1 - (values[i] - minV) / span)).toFloat() + h * 0.05f
            c.drawLine(prevX, prevY, x, y, p)
            prevX = x; prevY = y
        }
        return bmp
    }

    /** Mehrsegmentiger Donut. parts = Liste (wert, farbe). */
    fun donut(parts: List<Pair<Double, Int>>, sizePx: Int): Bitmap {
        val s = cap(sizePx)
        val bmp = Bitmap.createBitmap(s, s, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val total = parts.sumOf { it.first }
        val stroke = s * 0.16f
        val pad = stroke / 2f + 2f
        val rect = RectF(pad, pad, s - pad, s - pad)
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE; strokeWidth = stroke }
        if (total <= 0) { p.color = TRACK; c.drawArc(rect, 0f, 360f, false, p); return bmp }
        var start = -90f
        for ((v, col) in parts) {
            val sweep = (360.0 * (v / total)).toFloat()
            p.color = col; c.drawArc(rect, start, sweep, false, p)
            start += sweep
        }
        return bmp
    }
}
