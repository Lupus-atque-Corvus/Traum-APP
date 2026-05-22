import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRestKey = 'rest_duration_seconds';
const restDurationOptions = [60, 90, 120, 180];

final restDurationProvider =
    StateNotifierProvider<RestDurationNotifier, int>((ref) {
  return RestDurationNotifier();
});

class RestDurationNotifier extends StateNotifier<int> {
  RestDurationNotifier() : super(90) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kRestKey) ?? 90;
    if (mounted) state = restDurationOptions.contains(saved) ? saved : 90;
  }

  Future<void> set(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRestKey, seconds);
    state = seconds;
  }
}
