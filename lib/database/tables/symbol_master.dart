import 'package:drift/drift.dart';

/// Local search list: EQUITY_L.csv stocks plus the kept rows of the latest
/// bhavcopy that EQUITY_L lacks (all ETFs, and stocks in series such as
/// SM/ST).
@DataClassName('SymbolMasterData')
class SymbolMaster extends Table {
  TextColumn get isin => text()();

  TextColumn get symbol => text()();

  TextColumn get name => text()();

  /// `stock` | `etf`.
  TextColumn get type => text()();

  /// Not in the original spec; kept so a picked instrument gets its series.
  TextColumn get series => text().nullable()();

  /// `equity_l` (EQUITY_L.csv) | `bhavcopy` (ETFs, and stocks such as SM/ST
  /// that are not in EQUITY_L). Added in schema v2.
  TextColumn get origin => text().withDefault(const Constant('equity_l'))();

  @override
  Set<Column> get primaryKey => {isin};
}
