import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  ref.onDispose(() {
    database.close();
  });

  return database;
});
