import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  PinService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'traum_app_pin';

  static Future<bool> isSet() async {
    final value = await _storage.read(key: _key);
    return value != null && value.isNotEmpty;
  }

  static Future<void> save(String pin) async {
    await _storage.write(key: _key, value: pin);
  }

  static Future<bool> verify(String pin) async {
    final stored = await _storage.read(key: _key);
    return stored == pin;
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
