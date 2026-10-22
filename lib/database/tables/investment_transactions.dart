import 'package:drift/drift.dart';

import 'instruments.dart';

@DataClassName('InvestmentTransactionData')
class InvestmentTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get instrumentId => integer().references(Instruments, #id)();

  /// `opening` (no date) | `buy`.
  TextColumn get kind => text()();

  /// Quantity × 10,000.
  IntColumn get quantityScaled => integer()();

  IntColumn get pricePaise => integer()();

  IntColumn get feesPaise => integer().withDefault(const Constant(0))();

  /// `YYYY-MM-DD`; null means an opening position.
  TextColumn get date => text().nullable()();

  /// Up to 200 characters (schema v3).
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}
