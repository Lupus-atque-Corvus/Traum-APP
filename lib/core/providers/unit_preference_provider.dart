import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUnitKey = 'weight_unit';

final unitPreferenceProvider =
    StateNotifierProvider<UnitPreferenceNotifier, bool>((ref) {
  return UnitPreferenceNotifier();
});

/// true = lbs, false = kg (default)
class UnitPreferenceNotifier extends StateNotifier<bool> {
  UnitPreferenceNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) state = prefs.getBool(_kUnitKey) ?? false;
  }

  Future<void> setUseLbs(bool useLbs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUnitKey, useLbs);
    state = useLbs;
  }
}

extension WeightUnit on double {
  double toDisplayUnit(bool useLbs) => useLbs ? this * 2.20462 : this;
  String unitLabel(bool useLbs) => useLbs ? 'lbs' : 'kg';
}
