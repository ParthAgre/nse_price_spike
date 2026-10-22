import 'dart:convert';

import 'package:nse_price_spike/utils/trading_day.dart';

enum PriceMode {
  fixture,
  live;

  static PriceMode fromDb(String? value) =>
      value == 'live' ? PriceMode.live : PriceMode.fixture;
}

/// Keys of the `app_settings` key/value table.
abstract final class SettingKeys {
  static const priceMode = 'price_mode';
  static const lastFileTradeDate = 'last_file_trade_date';
  static const lastSuccessIstDate = 'last_success_ist_date';
  static const lastFileFetchedAt = 'last_file_fetched_at';
  static const lastFileSize = 'last_file_size';
  static const lastRowsParsed = 'last_rows_parsed';
  static const lastSeriesCounts = 'last_series_counts';
  static const lastHoldingsMatched = 'last_holdings_matched';
  static const equityListFetchedAt = 'equity_list_fetched_at';
  static const equityListRows = 'equity_list_rows';
  static const lastRefreshError = 'last_refresh_error';
  static const lastRefreshMessage = 'last_refresh_message';

  /// Keys describing the downloaded file; removed by "Clear cache".
  static const fileKeys = [
    lastFileTradeDate,
    lastSuccessIstDate,
    lastFileFetchedAt,
    lastFileSize,
    lastRowsParsed,
    lastSeriesCounts,
    lastHoldingsMatched,
    lastRefreshError,
    lastRefreshMessage,
  ];
}

/// Typed read-only view over the raw settings map.
class AppSettingsView {
  final Map<String, String> raw;

  const AppSettingsView(this.raw);

  PriceMode get mode => PriceMode.fromDb(raw[SettingKeys.priceMode]);
  DateTime? get lastFileTradeDate =>
      parseDateKey(raw[SettingKeys.lastFileTradeDate]);
  DateTime? get lastSuccessIstDate =>
      parseDateKey(raw[SettingKeys.lastSuccessIstDate]);
  DateTime? get lastFileFetchedAt =>
      DateTime.tryParse(raw[SettingKeys.lastFileFetchedAt] ?? '');
  int? get lastFileSize => int.tryParse(raw[SettingKeys.lastFileSize] ?? '');
  int? get lastRowsParsed =>
      int.tryParse(raw[SettingKeys.lastRowsParsed] ?? '');
  int? get lastHoldingsMatched =>
      int.tryParse(raw[SettingKeys.lastHoldingsMatched] ?? '');
  DateTime? get equityListFetchedAt =>
      DateTime.tryParse(raw[SettingKeys.equityListFetchedAt] ?? '');
  int? get equityListRows =>
      int.tryParse(raw[SettingKeys.equityListRows] ?? '');
  String? get lastRefreshError => raw[SettingKeys.lastRefreshError];
  String? get lastRefreshMessage => raw[SettingKeys.lastRefreshMessage];

  /// Series → row count, largest first.
  List<MapEntry<String, int>> get lastSeriesCounts {
    final text = raw[SettingKeys.lastSeriesCounts];
    if (text == null) return const [];
    try {
      final decoded = (jsonDecode(text) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      );
      return decoded.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    } on FormatException {
      return const [];
    }
  }
}
