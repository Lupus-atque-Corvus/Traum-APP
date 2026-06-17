import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  test('cycleProfileStreamProvider yields singleton profile', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    // Keep the autoDispose stream provider alive while awaiting its first
    // value — under Riverpod 3 an unlistened autoDispose provider may be
    // disposed during the loading state before the stream emits.
    final sub = container.listen(cycleProfileStreamProvider, (_, _) {});
    addTearDown(sub.close);

    final profile = await container.read(cycleProfileStreamProvider.future);
    expect(profile?.id, 0);
  });
}
