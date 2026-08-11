/// Escapes SQLite `LIKE` wildcard characters (`%`, `_`) and the escape
/// character itself (`\`) in [raw] so it can be safely embedded in a
/// `LIKE` pattern as a literal substring to search for.
///
/// Must be paired with `escapeChar: likeEscapeChar` on the `.like(...)`
/// call — without it, a user-typed `%` or `_` acts as a wildcard instead of
/// a literal character (e.g. searching for just `%` would match every row,
/// since `LIKE '%%%'` matches any string).
String escapeLikePattern(String raw) {
  return raw
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// The escape character used with [escapeLikePattern] — pass as
/// `escapeChar: likeEscapeChar` to every `.like(...)` call built from it.
const likeEscapeChar = r'\';
