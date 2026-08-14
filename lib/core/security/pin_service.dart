import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  PinService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'traum_app_pin';
  static const _failCountKey = 'traum_app_pin_fail_count';
  static const _lockedUntilKey = 'traum_app_pin_locked_until';

  /// Lockout backoff by consecutive failed attempt: the first 3 wrong PINs
  /// just show an error (matches the previous behaviour), then the wait
  /// grows with each further attempt up to a 5-minute cap — enough to make
  /// brute-forcing a 4-digit PIN impractical without locking a genuine user
  /// out for long after a couple of typos.
  static const List<int> _lockoutSecondsByAttempt = [30, 60, 120, 300];

  static int _lockoutSecondsFor(int failCount) {
    final overBy = failCount - 3;
    if (overBy <= 0) return 0;
    final index = overBy - 1;
    return _lockoutSecondsByAttempt[index.clamp(
      0,
      _lockoutSecondsByAttempt.length - 1,
    )];
  }

  static Future<bool> isSet() async {
    final value = await _storage.read(key: _key);
    return value != null && value.isNotEmpty;
  }

  static Future<void> save(String pin) async {
    await _storage.write(key: _key, value: pin);
    await _resetLockoutState();
  }

  /// Returns the moment the PIN entry unlocks again, or `null` if it isn't
  /// currently locked. Does not consume an attempt — safe to call from
  /// `initState`/countdown timers.
  static Future<DateTime?> getLockedUntil() async {
    final raw = await _storage.read(key: _lockedUntilKey);
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(ms);
    if (until.isAfter(DateTime.now())) return until;
    return null;
  }

  static Future<bool> verify(String pin) async {
    if (await getLockedUntil() != null) return false;

    final stored = await _storage.read(key: _key);
    final ok = stored == pin;
    if (ok) {
      await _resetLockoutState();
    } else {
      final failCount =
          (int.tryParse(await _storage.read(key: _failCountKey) ?? '') ?? 0) +
          1;
      await _storage.write(key: _failCountKey, value: failCount.toString());
      final lockoutSeconds = _lockoutSecondsFor(failCount);
      if (lockoutSeconds > 0) {
        final until = DateTime.now().add(Duration(seconds: lockoutSeconds));
        await _storage.write(
          key: _lockedUntilKey,
          value: until.millisecondsSinceEpoch.toString(),
        );
      }
    }
    return ok;
  }

  static Future<void> _resetLockoutState() async {
    await _storage.delete(key: _failCountKey);
    await _storage.delete(key: _lockedUntilKey);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
    await _resetLockoutState();
  }
}
