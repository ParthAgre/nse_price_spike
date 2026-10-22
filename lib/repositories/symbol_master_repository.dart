import 'package:drift/drift.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/instrument.dart';

class SymbolMasterRepository {
  final AppDatabase _db;

  SymbolMasterRepository(this._db);

  SymbolEntry _fromRow(SymbolMasterData r) => SymbolEntry(
    isin: r.isin,
    symbol: r.symbol,
    name: r.name,
    type: InstrumentType.fromDb(r.type),
    series: r.series,
  );

  static const originEquityList = 'equity_l';
  static const originBhavcopy = 'bhavcopy';

  /// Deletes every row of [origin], then inserts [entries] with [mode].
  Future<void> _replaceOrigin(
    String origin,
    List<SymbolEntry> entries,
    InsertMode mode,
  ) => _db.transaction(() async {
    await (_db.delete(
      _db.symbolMaster,
    )..where((t) => t.origin.equals(origin))).go();
    await _db.batch((b) {
      b.insertAll(_db.symbolMaster, [
        for (final e in entries)
          SymbolMasterCompanion.insert(
            isin: e.isin,
            symbol: e.symbol,
            name: e.name,
            type: e.type.name,
            series: Value(e.series),
            origin: Value(origin),
          ),
      ], mode: mode);
    });
  });

  /// Replaces the EQUITY_L rows. EQUITY_L wins over a bhavcopy row with the
  /// same ISIN.
  Future<void> replaceFromEquityList(List<SymbolEntry> entries) =>
      _replaceOrigin(originEquityList, entries, InsertMode.insertOrReplace);

  /// Replaces the rows that came from the latest bhavcopy: every kept row
  /// whose ISIN is not already listed from EQUITY_L (all ETFs, plus stocks
  /// such as SM/ST that EQUITY_L lacks).
  Future<void> replaceFromBhavcopy(List<SymbolEntry> entries) =>
      _replaceOrigin(originBhavcopy, entries, InsertMode.insertOrIgnore);

  Future<int> count() async {
    final countExp = _db.symbolMaster.isin.count();
    final row = await (_db.selectOnly(
      _db.symbolMaster,
    )..addColumns([countExp])).getSingle();
    return row.read(countExp) ?? 0;
  }

  Stream<List<SymbolEntry>> watchAll() => _db
      .select(_db.symbolMaster)
      .watch()
      .map((rows) => rows.map(_fromRow).toList());
}
