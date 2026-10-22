import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/repositories/fixed_deposit_repository.dart';
import 'package:nse_price_spike/repositories/holdings_repository.dart';
import 'package:nse_price_spike/repositories/price_repository.dart';

import '../helpers/fixtures.dart';

/// The schema exactly as v2 created it (from sqlite_master).
const _v2Schema = [
  'CREATE TABLE "instruments" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "isin" TEXT NOT NULL UNIQUE, "symbol" TEXT NOT NULL, "name" TEXT NOT NULL, "type" TEXT NOT NULL, "series" TEXT NULL)',
  'CREATE TABLE "investment_transactions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "instrument_id" INTEGER NOT NULL REFERENCES instruments (id), "kind" TEXT NOT NULL, "quantity_scaled" INTEGER NOT NULL, "price_paise" INTEGER NOT NULL, "fees_paise" INTEGER NOT NULL DEFAULT 0, "date" TEXT NULL, "created_at" INTEGER NOT NULL)',
  'CREATE TABLE "price_quotes" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "instrument_id" INTEGER NOT NULL REFERENCES instruments (id), "trade_date" TEXT NOT NULL, "close_paise" INTEGER NOT NULL, "prev_close_paise" INTEGER NULL, "source" TEXT NOT NULL, "fetched_at" INTEGER NOT NULL, UNIQUE ("instrument_id", "trade_date", "source"))',
  'CREATE TABLE "symbol_master" ("isin" TEXT NOT NULL, "symbol" TEXT NOT NULL, "name" TEXT NOT NULL, "type" TEXT NOT NULL, "series" TEXT NULL, "origin" TEXT NOT NULL DEFAULT \'equity_l\', PRIMARY KEY ("isin"))',
  'CREATE TABLE "app_settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"))',
];

void main() {
  test('v2 → v3 adds fixed_deposits and notes; holdings survive', () async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            for (final sql in _v2Schema) {
              raw.execute(sql);
            }
            raw.execute(
              "INSERT INTO instruments VALUES (1, 'INE002A01018', 'RELIANCE', "
              "'Reliance Industries Limited', 'stock', 'EQ')",
            );
            raw.execute(
              'INSERT INTO investment_transactions VALUES '
              "(1, 1, 'opening', 100000, 110000, 0, NULL, 1792000000)",
            );
            raw.execute(
              'INSERT INTO price_quotes VALUES '
              "(1, 1, '2026-10-21', 120900, 120200, 'nse_bhavcopy', 1792000000)",
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);

    final holdings = await HoldingsRepository(
      db,
      PriceRepository(db),
    ).loadHoldings();
    expect(holdings, hasLength(1));
    final reliance = holdings.single;
    expect(reliance.instrument.symbol, 'RELIANCE');
    expect(reliance.quantityScaled, 100000);
    expect(reliance.investedPaise, 1100000);
    expect(reliance.valuePaise, 1209000);
    expect(reliance.dayChangePaise, 7000);
    expect(reliance.entries.single.notes, isNull);

    // The new column and table are usable.
    await HoldingsRepository(db, PriceRepository(db)).updateEntry(
      entryId: 1,
      quantityScaled: 100000,
      pricePaise: 110000,
      feesPaise: 0,
      date: null,
      notes: 'From the old app',
    );
    final repo = FixedDepositRepository(db);
    await repo.add(
      FdDraft(
        institution: 'HDFC Bank',
        principalPaise: 10000000,
        rateMilliPct: 7000,
        startDate: d('2026-01-01'),
        maturityDate: d('2027-01-01'),
      ),
      now: DateTime.utc(2026, 10, 22),
    );
    expect(await repo.all(), hasLength(1));
    final after = await HoldingsRepository(
      db,
      PriceRepository(db),
    ).loadHoldings();
    expect(after.single.entries.single.notes, 'From the old app');

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 3);
  });
}
