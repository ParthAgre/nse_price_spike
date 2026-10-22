import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/app_settings.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
    await delete(appSettings).go();
  });
}

QueryExecutor _openConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$databaseFileName');
  return NativeDatabase.createInBackground(file);
});
