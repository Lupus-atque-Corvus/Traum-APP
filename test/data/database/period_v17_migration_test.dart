import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('DailyLogs persists bbt, mucus, mood, energy, sex', () async {
    final id = await db.periodDao.upsertDailyLog(
      DailyLogsCompanion.insert(
        logDate: DateTime(2026, 6, 15),
        bbt: const Value(36.72),
        cervicalMucus: const Value(4), // eggWhite
        mood: const Value(3),
        energy: const Value(4),
        sexEvent: const Value(2), // unprotected
      ),
    );
    expect(id, greaterThan(0));
    final log = await db.periodDao.getDailyLogForDate(DateTime(2026, 6, 15));
    expect(log!.bbt, 36.72);
    expect(log.cervicalMucus, 4);
    expect(log.sexEvent, 2);
  });

  test('CycleProfile singleton exists with id 0 after open', () async {
    final profile = await db.periodDao.getCycleProfile();
    expect(profile.id, 0);
    expect(profile.menarcheDate, isNull);
  });
}
