/// A single price record the service can match against. Decoupled from drift so
/// the matching logic is pure and unit-testable.
class PriceEntry {
  final String name;
  final String normalized;
  final double price;
  final String? unit;
  const PriceEntry({
    required this.name,
    required this.normalized,
    required this.price,
    this.unit,
  });
}

/// Result of a successful price match.
class PriceMatch {
  final String name;
  final double price;
  final String? unit;
  const PriceMatch({required this.name, required this.price, this.unit});
}

/// Suggests an approximate price for a typed grocery name.
class GroceryPriceService {
  /// Normalises a product name: lowercase, German umlaut/ß expansion, diacritic
  /// stripping, punctuation → space, collapsed whitespace.
  static String normalizeName(String raw) {
    var s = raw.toLowerCase().trim();
    const umlauts = {
      'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss',
      'á': 'a', 'à': 'a', 'â': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u',
    };
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      buffer.write(umlauts[ch] ?? ch);
    }
    s = buffer.toString();
    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Returns the best price match for [rawName] among [prices], or null.
  /// Order: exact normalized → contains (either direction) → fuzzy (Levenshtein).
  static PriceMatch? match(String rawName, List<PriceEntry> prices) {
    final q = normalizeName(rawName);
    if (q.isEmpty || prices.isEmpty) return null;

    // 1. Exact
    for (final p in prices) {
      if (p.normalized == q) {
        return PriceMatch(name: p.name, price: p.price, unit: p.unit);
      }
    }

    // 2. Contains (prefer the shortest containing entry = closest concept)
    PriceEntry? containBest;
    for (final p in prices) {
      if (p.normalized.contains(q) || q.contains(p.normalized)) {
        if (containBest == null ||
            p.normalized.length < containBest.normalized.length) {
          containBest = p;
        }
      }
    }
    if (containBest != null) {
      return PriceMatch(
          name: containBest.name,
          price: containBest.price,
          unit: containBest.unit);
    }

    // 3. Fuzzy — accept if edit distance ≤ 2 and ≤ 25% of length.
    PriceEntry? fuzzyBest;
    int fuzzyDist = 1 << 30;
    final threshold = (q.length * 0.25).ceil().clamp(1, 2);
    for (final p in prices) {
      final d = _levenshtein(q, p.normalized);
      if (d <= threshold && d < fuzzyDist) {
        fuzzyDist = d;
        fuzzyBest = p;
      }
    }
    if (fuzzyBest != null) {
      return PriceMatch(
          name: fuzzyBest.name, price: fuzzyBest.price, unit: fuzzyBest.unit);
    }

    return null;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = [
          curr[j] + 1,
          prev[j + 1] + 1,
          prev[j] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev.setRange(0, b.length + 1, curr);
    }
    return prev[b.length];
  }
}
