import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:nse_price_spike/database/app_database.dart';

/// In-memory [AppDatabase] for tests.
///
/// `closeStreamsSynchronously` stops drift keeping a stream alive for one
/// event-loop turn after its last listener detaches (a `Timer.run`), which
/// would otherwise trip the widget-test "Timer is still pending" check.
AppDatabase createTestDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}
