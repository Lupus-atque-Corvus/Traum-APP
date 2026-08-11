/// Parses a locale-formatted decimal amount (comma as decimal separator,
/// as used throughout the app's number fields) into a [double].
///
/// Returns `null` if [raw] is empty or not a valid number, exactly like
/// [double.tryParse] — callers keep their existing null-handling.
double? parseLocaleAmount(String raw) {
  return double.tryParse(raw.trim().replaceAll(',', '.'));
}
