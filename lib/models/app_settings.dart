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
  static const lastKeptSeriesCounts = 'last_kept_series_counts';

  /// When today's file last returned 404 (not published yet).
  static const todayPendingCheckedAt = 'today_pending_checked_at';

  /// JSON list of [PublishLogEntry]; kept by "Clear cache" (it's measurement
  /// data, not cached prices).
  static const publishLog = 'publish_log';

  /// Keys describing the downloaded file; removed by "Clear cache".
  static const fileKeys = [
    lastFileTradeDate,
    lastSuccessIstDate,
    lastFileFetchedAt,
    lastFileSize,
    lastRowsParsed,
    lastSeriesCounts,
    lastKeptSeriesCounts,
    lastHoldingsMatched,
    lastRefreshError,
    lastRefreshMessage,
    todayPendingCheckedAt,
  ];
}

/// One successful download, recorded to measure when NSE publishes.
class PublishLogEntry {
  final DateTime tradeDate;
  final DateTime fetchedAt;
  final String source;

  /// HTTP `Last-Modified` (live downloads only).
  final DateTime? lastModified;

  /// The CSV's timestamp inside the zip, read as IST.
  final DateTime? zipEntryTime;

  const PublishLogEntry({
    required this.tradeDate,
    required this.fetchedAt,
    required this.source,
    this.lastModified,
    this.zipEntryTime,
  });

  Map<String, String?> toJson() => {
    'tradeDate': dateKey(tradeDate),
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'source': source,
    'lastModified': lastModified?.toUtc().toIso8601String(),
    'zipEntryTime': zipEntryTime?.toUtc().toIso8601String(),
  };

  static PublishLogEntry? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final tradeDate = parseDateKey(json['tradeDate'] as String?);
    final fetchedAt = DateTime.tryParse(json['fetchedAt'] as String? ?? '');
    if (tradeDate == null || fetchedAt == null) return null;
    return PublishLogEntry(
      tradeDate: tradeDate,
      fetchedAt: fetchedAt,
      source: json['source'] as String? ?? '',
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? ''),
      zipEntryTime: DateTime.tryParse(json['zipEntryTime'] as String? ?? ''),
    );
  }
}

const publishLogCapacity = 30;

/// Newest first, capped at [publishLogCapacity]; returns JSON-ready maps.
List<Map<String, String?>> appendPublishLog(
  List<PublishLogEntry> log,
  PublishLogEntry entry,
) => [
  entry.toJson(),
  for (final e in log.take(publishLogCapacity - 1)) e.toJson(),
];

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
  DateTime? get todayPendingCheckedAt =>
      DateTime.tryParse(raw[SettingKeys.todayPendingCheckedAt] ?? '');

  List<PublishLogEntry> get publishLog {
    final text = raw[SettingKeys.publishLog];
    if (text == null) return const [];
    try {
      final list = jsonDecode(text);
      if (list is! List) return const [];
      return [for (final item in list) ?PublishLogEntry.fromJson(item)];
    } on FormatException {
      return const [];
    }
  }

  List<MapEntry<String, int>> get lastKeptSeriesCounts =>
      _countsFrom(raw[SettingKeys.lastKeptSeriesCounts]);

  /// Series → row count (all rows), largest first.
  List<MapEntry<String, int>> get lastSeriesCounts =>
      _countsFrom(raw[SettingKeys.lastSeriesCounts]);

  /// A JSON `{series: count}` map as entries, largest first.
  static List<MapEntry<String, int>> _countsFrom(String? text) {
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
