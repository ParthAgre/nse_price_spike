import 'package:drift/drift.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

FixedDeposit fixedDepositFromRow(FixedDepositData r) => FixedDeposit(
  id: r.id,
  draft: FdDraft(
    institution: r.institution,
    nickname: r.nickname,
    principalPaise: r.principalPaise,
    rateMilliPct: r.rateMilliPct,
    startDate: parseDateKey(r.startDate)!,
    maturityDate: parseDateKey(r.maturityDate)!,
    interestType: r.interestType == FdInterestType.payout.name
        ? FdInterestType.payout
        : FdInterestType.cumulative,
    compounding: FdFrequency.tryParse(r.compounding) ?? FdFrequency.quarterly,
    payoutFrequency: FdFrequency.tryParse(r.payoutFrequency),
    receiptMaturityPaise: r.receiptMaturityPaise,
    payoutAmountPaise: r.payoutAmountPaise,
    notes: r.notes,
  ),
  closure: FdClosure.fromDb(r.status),
  closedOn: parseDateKey(r.closedOn),
  amountReceivedPaise: r.amountReceivedPaise,
  renewedIntoId: r.renewedIntoId,
  createdAt: r.createdAt,
);

class FixedDepositRepository {
  final AppDatabase _db;

  FixedDepositRepository(this._db);

  FixedDepositsCompanion _fields(FdDraft d) {
    final cumulative = d.interestType == FdInterestType.cumulative;
    return FixedDepositsCompanion(
      institution: Value(d.institution.trim()),
      nickname: Value(_blankToNull(d.nickname)),
      principalPaise: Value(d.principalPaise),
      rateMilliPct: Value(d.rateMilliPct),
      startDate: Value(dateKey(d.startDate)),
      maturityDate: Value(dateKey(d.maturityDate)),
      interestType: Value(d.interestType.name),
      payoutFrequency: Value(
        cumulative ? null : (d.payoutFrequency ?? FdFrequency.monthly).name,
      ),
      compounding: Value(d.compounding.name),
      receiptMaturityPaise: Value(cumulative ? d.receiptMaturityPaise : null),
      payoutAmountPaise: Value(cumulative ? null : d.payoutAmountPaise),
      notes: Value(_blankToNull(d.notes)),
    );
  }

  static String? _blankToNull(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  Future<int> add(FdDraft draft, {required DateTime now}) => _db
      .into(_db.fixedDeposits)
      .insert(_fields(draft).copyWith(createdAt: Value(now)));

  Future<void> edit(int id, FdDraft draft) => (_db.update(
    _db.fixedDeposits,
  )..where((t) => t.id.equals(id))).write(_fields(draft));

  /// Withdrawn at maturity, or closed early.
  Future<void> close(
    int id, {
    required FdClosure closure,
    required DateTime closedOn,
    required int amountReceivedPaise,
  }) => (_db.update(_db.fixedDeposits)..where((t) => t.id.equals(id))).write(
    FixedDepositsCompanion(
      status: Value(closure.dbValue),
      closedOn: Value(dateKey(closedOn)),
      amountReceivedPaise: Value(amountReceivedPaise),
    ),
  );

  /// Saves [next] as a new FD and closes [old] as renewed (on its maturity
  /// date, for its maturity amount), linked to the new one. Returns the new
  /// FD's id.
  Future<int> renew(FixedDeposit old, FdDraft next, {required DateTime now}) =>
      _db.transaction(() async {
        final newId = await add(next, now: now);
        await (_db.update(
          _db.fixedDeposits,
        )..where((t) => t.id.equals(old.id))).write(
          FixedDepositsCompanion(
            status: Value(FdClosure.renewed.dbValue),
            closedOn: Value(dateKey(old.maturityDate)),
            amountReceivedPaise: Value(old.maturityAmount),
            renewedIntoId: Value(newId),
          ),
        );
        return newId;
      });

  /// Deletes the FD and clears links to it.
  Future<void> delete(int id) => _db.transaction(() async {
    await (_db.update(_db.fixedDeposits)
          ..where((t) => t.renewedIntoId.equals(id)))
        .write(const FixedDepositsCompanion(renewedIntoId: Value(null)));
    await (_db.delete(_db.fixedDeposits)..where((t) => t.id.equals(id))).go();
  });

  Stream<List<FixedDeposit>> watchAll() =>
      (_db.select(_db.fixedDeposits)..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch()
          .map((rows) => rows.map(fixedDepositFromRow).toList());

  Future<List<FixedDeposit>> all() async =>
      (await _db.select(_db.fixedDeposits).get())
          .map(fixedDepositFromRow)
          .toList();

  /// Institutions used before, most used first, for form suggestions.
  Stream<List<String>> watchInstitutions() => watchAll().map((list) {
    final counts = <String, int>{};
    for (final fd in list) {
      counts.update(fd.institution, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  });
}
