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

  Future<void> _replaceType(InstrumentType type, List<SymbolEntry> entries) =>
      _db.transaction(() async {
        await (_db.delete(
          _db.symbolMaster,
        )..where((t) => t.type.equals(type.name))).go();
        await _db.batch((b) {
          b.insertAll(_db.symbolMaster, [
            for (final e in entries.where((e) => e.type == type))
              SymbolMasterCompanion.insert(
                isin: e.isin,
                symbol: e.symbol,
                name: e.name,
                type: e.type.name,
                series: Value(e.series),
              ),
          ], mode: InsertMode.insertOrReplace);
        });
      });

  /// Replaces all stock rows (from EQUITY_L.csv); ETF rows are untouched.
  Future<void> replaceStocks(List<SymbolEntry> entries) =>
      _replaceType(InstrumentType.stock, entries);

  /// Replaces all ETF rows (from the latest bhavcopy); stocks are untouched.
  Future<void> replaceEtfs(List<SymbolEntry> entries) =>
      _replaceType(InstrumentType.etf, entries);

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
