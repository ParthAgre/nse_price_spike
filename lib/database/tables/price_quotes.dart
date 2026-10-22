import 'package:drift/drift.dart';

import 'instruments.dart';

@DataClassName('PriceQuoteData')
class PriceQuotes extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get instrumentId => integer().references(Instruments, #id)();

  /// `YYYY-MM-DD` (sorts as text).
  TextColumn get tradeDate => text()();

  IntColumn get closePaise => integer()();

  IntColumn get prevClosePaise => integer().nullable()();

  /// `nse_bhavcopy` | `manual`.
  TextColumn get source => text()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {instrumentId, tradeDate, source},
  ];
}
