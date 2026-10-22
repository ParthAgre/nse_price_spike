import 'package:drift/drift.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/instrument.dart';

Instrument instrumentFromRow(InstrumentData r) => Instrument(
  id: r.id,
  isin: r.isin,
  symbol: r.symbol,
  name: r.name,
  type: InstrumentType.fromDb(r.type),
  series: r.series,
);

class InstrumentRepository {
  final AppDatabase _db;

  InstrumentRepository(this._db);

  /// Inserts the instrument, or refreshes symbol/name/type/series of the
  /// existing row with the same ISIN. Returns the stored instrument.
  Future<Instrument> upsert(SymbolEntry entry) async {
    await _db
        .into(_db.instruments)
        .insert(
          InstrumentsCompanion.insert(
            isin: entry.isin,
            symbol: entry.symbol,
            name: entry.name,
            type: entry.type.name,
            series: Value(entry.series),
          ),
          onConflict: DoUpdate(
            (_) => InstrumentsCompanion(
              symbol: Value(entry.symbol),
              name: Value(entry.name),
              type: Value(entry.type.name),
              series: Value(entry.series),
            ),
            target: [_db.instruments.isin],
          ),
        );
    final row = await (_db.select(
      _db.instruments,
    )..where((t) => t.isin.equals(entry.isin))).getSingle();
    return instrumentFromRow(row);
  }

  Future<Instrument?> byId(int id) async {
    final row = await (_db.select(
      _db.instruments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : instrumentFromRow(row);
  }
}
