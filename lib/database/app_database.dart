import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/app_settings.dart';
import 'tables/fixed_deposits.dart';
import 'tables/instruments.dart';
import 'tables/investment_transactions.dart';
import 'tables/price_quotes.dart';
import 'tables/symbol_master.dart';

part 'app_database.g.dart';

const databaseFileName = 'nse_price_spike.sqlite';

@DriftDatabase(
  tables: [
    Instruments,
    InvestmentTransactions,
    PriceQuotes,
    SymbolMaster,
    AppSettings,
    FixedDeposits,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: symbol_master.origin. Until v2, ETFs were the only rows that
        // came from the bhavcopy.
        await m.addColumn(symbolMaster, symbolMaster.origin);
        await customStatement(
          "UPDATE symbol_master SET origin = 'bhavcopy' WHERE type = 'etf'",
        );
      }
      if (from < 3) {
        // v3: fixed deposits, and notes on stock/ETF entries.
        await m.createTable(fixedDeposits);
        await m.addColumn(investmentTransactions, investmentTransactions.notes);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Deletes every row in every table ("Reset database").
  Future<void> wipeAll() => transaction(() async {
    await delete(priceQuotes).go();
    await delete(investmentTransactions).go();
    await delete(instruments).go();
    await delete(symbolMaster).go();
    await delete(fixedDeposits).go();
    await delete(appSettings).go();
  });
}

QueryExecutor _openConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$databaseFileName');
  return NativeDatabase.createInBackground(file);
});
