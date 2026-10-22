import 'package:drift/drift.dart';

@DataClassName('InstrumentData')
class Instruments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Identity across files; symbols can change.
  TextColumn get isin => text().unique()();

  TextColumn get symbol => text()();

  TextColumn get name => text()();

  /// `stock` | `etf`.
  TextColumn get type => text()();

  TextColumn get series => text().nullable()();
}
