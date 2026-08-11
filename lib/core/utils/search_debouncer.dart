import 'dart:async';

/// Debounces search text input so filtering large lists doesn't run on
/// every keystroke while typing. Shared by every search field in the app
/// (exercise library/picker/wizard, diary, budget transactions) instead of
/// each screen reimplementing its own `Timer`.
class SearchDebouncer {
  SearchDebouncer({this.duration = const Duration(milliseconds: 250)});

  final Duration duration;
  Timer? _timer;

  void call(String value, void Function(String settled) onSettled) {
    _timer?.cancel();
    _timer = Timer(duration, () => onSettled(value));
  }

  void dispose() => _timer?.cancel();
}
