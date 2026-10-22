import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/app_settings.dart';

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  Map<String, String> _toMap(List<AppSettingData> rows) => {
    for (final r in rows) r.key: r.value,
  };

  Stream<AppSettingsView> watch() => _db
      .select(_db.appSettings)
      .watch()
      .map((rows) => AppSettingsView(_toMap(rows)));

  Future<AppSettingsView> read() async =>
      AppSettingsView(_toMap(await _db.select(_db.appSettings).get()));

  /// Writes every entry; a null value removes the key.
  Future<void> setAll(Map<String, String?> values) => _db.transaction(() async {
    for (final MapEntry(:key, :value) in values.entries) {
      if (value == null) {
        await (_db.delete(
          _db.appSettings,
        )..where((t) => t.key.equals(key))).go();
      } else {
        await _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(key: key, value: value),
            );
      }
    }
  });

  Future<void> set(String key, String? value) => setAll({key: value});

  Future<void> setMode(PriceMode mode) => set(SettingKeys.priceMode, mode.name);
}
