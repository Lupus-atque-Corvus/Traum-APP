import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/preferences_provider.dart';
import 'home_seed.dart';
import 'home_tile.dart';
import 'home_widget_registry.dart';

const _kHomeLayoutKey = 'home_layout_v1';

class HomeLayoutNotifier extends StateNotifier<List<HomeTile>> {
  final SharedPreferences _prefs;
  HomeLayoutNotifier(this._prefs) : super(const []) {
    final raw = _prefs.getString(_kHomeLayoutKey);
    if (raw == null) {
      state = defaultHomeLayout();
    } else {
      final decoded = decodeHomeLayout(raw);
      state = decoded.isEmpty ? defaultHomeLayout() : decoded;
    }
  }

  void _persist() => _prefs.setString(_kHomeLayoutKey, encodeHomeLayout(state));

  void add(HomeWidgetType type) {
    final d = descriptorFor(type);
    final size = d?.defaultSize ?? HomeTileSize.small;
    state = [...state, HomeTile(type: type, size: size)];
    _persist();
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    final copy = [...state]..removeAt(index);
    state = copy;
    _persist();
  }

  void cycleSize(int index) {
    if (index < 0 || index >= state.length) return;
    final t = state[index];
    final copy = [...state];
    copy[index] = HomeTile(type: t.type, size: nextSize(t.type, t.size));
    state = copy;
    _persist();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    final copy = [...state];
    final item = copy.removeAt(oldIndex);
    final target = newIndex.clamp(0, copy.length);
    copy.insert(target, item);
    state = copy;
    _persist();
  }

  void resetToDefault() {
    state = defaultHomeLayout();
    _persist();
  }

  /// Setzt ein an die Onboarding-Interessen angepasstes Start-Layout.
  void seedFromModules(Set<String> modules) {
    state = seededLayoutForModules(modules);
    _persist();
  }
}

final homeLayoutProvider =
    StateNotifierProvider<HomeLayoutNotifier, List<HomeTile>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HomeLayoutNotifier(prefs);
});
