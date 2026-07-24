import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/data/preferences/preferences_repository.dart';

void main() {
  test('substancesDisclaimerAccepted defaults to false and persists when set', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PreferencesRepository(prefs);

    expect(repo.substancesDisclaimerAccepted, isFalse);

    await repo.setSubstancesDisclaimerAccepted(true);
    expect(repo.substancesDisclaimerAccepted, isTrue);
  });
}
