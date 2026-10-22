import 'package:drift/drift.dart';

/// Local search list: EQUITY_L.csv stocks plus the ETF (INF) rows of the
/// latest bhavcopy.
@DataClassName('SymbolMasterData')
class SymbolMaster extends Table {
  TextColumn get isin => text()();

  TextColumn get symbol => text()();

  TextColumn get name => text()();

  /// `stock` | `etf`.
  TextColumn get type => text()();

  /// Not in the original spec; kept so a picked instrument gets its series.
  TextColumn get series => text().nullable()();

  @override
  Set<Column> get primaryKey => {isin};
}
