/// Parses a locale-formatted decimal amount (comma as decimal separator,
/// as used throughout the app's number fields) into a [double].
///
/// Returns `null` if [raw] is empty or not a valid number, exactly like
/// [double.tryParse] — callers keep their existing null-handling.
double? parseLocaleAmount(String raw) {
  return double.tryParse(raw.trim().replaceAll(',', '.'));
}

/// Sane upper bound for a single monetary amount anywhere in the app. Real
/// personal finances never approach this — it exists purely to catch fat-
/// finger numpad input (e.g. an extra held-down digit producing something
/// like 1e44) before it reaches formatting/charting code downstream, which
/// assumes realistic magnitudes and breaks (scientific notation, `RangeError`
/// from string-splitting logic that expects a normal decimal point) once a
/// value gets large enough that `toStringAsFixed` itself switches to
/// exponential notation.
const kMaxAmount = 50000000.0;
