// test/data/repositories/substance_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/repositories/substance_repository.dart';
import 'package:traum/data/services/substance_reference_db_service.dart';

const _fixturePath = 'test/fixtures/substances_reference_fixture.sqlite3';

void main() {
  late SubstanceRepository repo;
  late SubstanceReferenceDbService service;

  setUp(() {
    service = SubstanceReferenceDbService(_fixturePath);
    repo = SubstanceRepository(service);
  });
  tearDown(() => service.dispose());

  test('search delegates to the service', () async {
    final results = await repo.search('ibuprofen');
    expect(results, isNotEmpty);
  });

  test('findById delegates to the service', () async {
    final all = await repo.search('ibuprofen');
    final found = await repo.findById(all.first.id);
    expect(found?.folder, 'Ibuprofen');
  });

  test('listCategories delegates to the service', () async {
    expect(await repo.listCategories(), isNotEmpty);
  });

  test('topNebenwirkungen delegates to the service', () async {
    final all = await repo.search('ibuprofen');
    // Should not throw even if empty for this fixture row.
    await repo.topNebenwirkungen(all.first.id);
  });
}
