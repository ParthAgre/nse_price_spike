import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/repositories/symbol_master_repository.dart';

void main() {
  test('v1 → v2 adds symbol_master.origin and tags existing ETFs', () async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            // symbol_master exactly as schema v1 created it.
            raw.execute('''
              CREATE TABLE symbol_master (
                isin TEXT NOT NULL, symbol TEXT NOT NULL, name TEXT NOT NULL,
                type TEXT NOT NULL, series TEXT NULL, PRIMARY KEY (isin))
            ''');
            // The other v1 tables that later steps alter (unchanged in v2).
            raw.execute(
              'CREATE TABLE "instruments" ("id" INTEGER NOT NULL PRIMARY KEY '
              'AUTOINCREMENT, "isin" TEXT NOT NULL UNIQUE, "symbol" TEXT NOT '
              'NULL, "name" TEXT NOT NULL, "type" TEXT NOT NULL, "series" '
              'TEXT NULL)',
            );
            raw.execute(
              'CREATE TABLE "investment_transactions" ("id" INTEGER NOT NULL '
              'PRIMARY KEY AUTOINCREMENT, "instrument_id" INTEGER NOT NULL '
              'REFERENCES instruments (id), "kind" TEXT NOT NULL, '
              '"quantity_scaled" INTEGER NOT NULL, "price_paise" INTEGER NOT '
              'NULL, "fees_paise" INTEGER NOT NULL DEFAULT 0, "date" TEXT '
              'NULL, "created_at" INTEGER NOT NULL)',
            );
            raw.execute(
              "INSERT INTO symbol_master VALUES "
              "('INE002A01018','RELIANCE','Reliance','stock','EQ'),"
              "('INF204KB14I2','NIFTYBEES','Nifty BeES','etf','EQ')",
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);

    final rows = await db.select(db.symbolMaster).get();
    final origin = {for (final r in rows) r.symbol: r.origin};
    expect(origin, {'RELIANCE': 'equity_l', 'NIFTYBEES': 'bhavcopy'});

    // A bhavcopy refresh now replaces only the bhavcopy-origin rows.
    await SymbolMasterRepository(db).replaceFromBhavcopy(const [
      SymbolEntry(
        isin: 'INE0O6N01012',
        symbol: 'AGUL',
        name: 'A G Universal',
        type: InstrumentType.stock,
        series: 'SM',
      ),
    ]);
    final after = await db.select(db.symbolMaster).get();
    expect(after.map((r) => r.symbol).toSet(), {'RELIANCE', 'AGUL'});
  });
}
