import 'package:drift/drift.dart';

/// Small key/value store (mode toggle, download bookkeeping, file stats).
@DataClassName('AppSettingData')
class AppSettings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
