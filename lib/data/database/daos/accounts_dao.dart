import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<TraumDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<Account>> getAll() =>
      (select(accounts)
            ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
          .get();

  Stream<List<Account>> watchAll() =>
      (select(accounts)
            ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
          .watch();

  Future<Account?> getById(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<double> getTotalBalance() async {
    final all = await getAll();
    return all.fold<double>(0.0, (sum, a) => sum + a.balance);
  }

  Future<void> upsertAccount(AccountsCompanion account) =>
      into(accounts).insertOnConflictUpdate(account);

  Future<void> deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();
}
