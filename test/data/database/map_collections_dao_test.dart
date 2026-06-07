import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;

  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('updateCollection persists changed fields', () async {
    final id = await db.mapCollectionsDao.insert(
      MapCollectionsCompanion.insert(
        name: 'Alt',
        iconName: 'map',
        fieldConfig: const Value('{"groupRadius":50}'),
        createdAt: DateTime.now(),
      ),
    );
    final original = await db.mapCollectionsDao.getById(id);

    await db.mapCollectionsDao.updateCollection(
      original!.copyWith(
        name: 'Neu',
        multiPhoto: true,
        fieldConfig: '{"groupRadius":120}',
      ),
    );

    final updated = await db.mapCollectionsDao.getById(id);
    expect(updated!.name, 'Neu');
    expect(updated.multiPhoto, isTrue);
    expect(updated.fieldConfig, contains('120'));
  });
}
