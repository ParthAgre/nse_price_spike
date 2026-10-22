import 'dart:convert';

import 'package:nse_price_spike/models/app_settings.dart';
import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/repositories/holdings_repository.dart';
import 'package:nse_price_spike/repositories/price_repository.dart';
import 'package:nse_price_spike/repositories/settings_repository.dart';
import 'package:nse_price_spike/repositories/symbol_master_repository.dart';
import 'package:nse_price_spike/services/bhavcopy_parser.dart';
import 'package:nse_price_spike/services/file_cache.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';
import 'package:nse_price_spike/services/price_provider.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

String pricesAsOf(DateTime? fileDate) => fileDate == null
    ? 'no prices yet'
    : 'prices as of ${formatDisplayDate(fileDate)}';

sealed class RefreshOutcome {
  const RefreshOutcome();

  String get message;
  bool get isError => false;
}

/// The stored file is already the expected latest trading day.
class UpToDate extends RefreshOutcome {
  final DateTime fileDate;
  const UpToDate(this.fileDate);

  @override
  String get message => 'Up to date — ${pricesAsOf(fileDate)}';
}

/// A file was already downloaded today (IST); one download per day.
class AlreadyDownloadedToday extends RefreshOutcome {
  final DateTime? fileDate;
  const AlreadyDownloadedToday(this.fileDate);

  @override
  String get message =>
      'Already downloaded today — ${pricesAsOf(fileDate)}. '
      'Use "Download now" on the Debug screen to force.';
}

class Downloaded extends RefreshOutcome {
  final DailyFile file;
  final int attempts;
  final int holdingsMatched;

  /// Today's file 404'd and an earlier day was fetched instead.
  final bool todayPending;

  const Downloaded(
    this.file,
    this.attempts,
    this.holdingsMatched, {
    this.todayPending = false,
  });

  @override
  String get message => todayPending
      ? 'Downloaded NSE file for ${formatDisplayDate(file.tradeDate)}; '
            "today's file isn't published yet"
      : 'Downloaded NSE file for ${formatDisplayDate(file.tradeDate)}';
}

/// Today's file returned 404: not published yet. Previous prices are kept
/// and the next open/resume retries (at most every 30 minutes).
class NotPublishedYet extends RefreshOutcome {
  final DateTime? fileDate;
  final DateTime nextCheckAt;
  const NotPublishedYet(this.fileDate, this.nextCheckAt);

  @override
  String get message =>
      "Today's NSE file isn't published yet — ${pricesAsOf(fileDate)}";
}

/// Every day tried returned 404 (holidays / not published yet), or the
/// fallback reached a day that is already stored.
class NoNewFile extends RefreshOutcome {
  final int attempts;
  final DateTime? fileDate;
  const NoNewFile(this.attempts, this.fileDate);

  @override
  String get message => 'No newer NSE file yet — ${pricesAsOf(fileDate)}';
}

/// 403, timeout, non-zip body, parse failure or any unexpected error.
/// Cached prices are kept.
class RefreshFailed extends RefreshOutcome {
  final Object error;
  final DateTime? fileDate;
  const RefreshFailed(this.error, this.fileDate);

  @override
  bool get isError => true;

  String get detail => error is PriceFetchException
      ? (error as PriceFetchException).message
      : '$error';

  @override
  String get message => "Couldn't reach NSE — ${pricesAsOf(fileDate)}";
}

sealed class EquityListOutcome {
  const EquityListOutcome();
}

class EquityListSkipped extends EquityListOutcome {
  const EquityListSkipped();
}

class EquityListUpdated extends EquityListOutcome {
  final int stocks;
  const EquityListUpdated(this.stocks);
}

class EquityListFailed extends EquityListOutcome {
  final Object error;
  const EquityListFailed(this.error);
}

/// Decides when to download, walks back over holidays, and stores results.
/// Never throws: every failure becomes an outcome.
class RefreshService {
  static const maxAttempts = 5;

  /// Minimum gap between automatic re-checks for an unpublished today file.
  static const pendingRetry = Duration(minutes: 30);
  static const equityListMaxAge = Duration(days: 7);

  final PriceProvider provider;
  final SettingsRepository settings;
  final HoldingsRepository holdings;
  final PriceRepository prices;
  final SymbolMasterRepository symbols;
  final FileCache cache;
  final DateTime Function() clock;
  final bool useIsolate;

  RefreshService({
    required this.provider,
    required this.settings,
    required this.holdings,
    required this.prices,
    required this.symbols,
    required this.cache,
    this.clock = DateTime.now,
    this.useIsolate = true,
  });

  /// Downloads EQUITY_L.csv on first run (empty symbol master), when older
  /// than a week, or when [force]d.
  Future<EquityListOutcome> refreshEquityList({bool force = false}) async {
    try {
      final now = clock();
      final view = await settings.read();
      final fetchedAt = view.equityListFetchedAt;
      final stale =
          fetchedAt == null || now.difference(fetchedAt) >= equityListMaxAge;
      if (!force && !stale && await symbols.count() > 0) {
        return const EquityListSkipped();
      }
      final list = await provider.fetchEquityList();
      final stocks = list.entries
          .where((e) => e.type == InstrumentType.stock)
          .toList();
      if (stocks.isEmpty) {
        throw const PriceParseFailure('EQUITY_L.csv had no INE rows');
      }
      await symbols.replaceFromEquityList(stocks);
      await settings.setAll({
        SettingKeys.equityListFetchedAt: now.toUtc().toIso8601String(),
        SettingKeys.equityListRows: '${list.rowsParsed}',
      });
      return EquityListUpdated(stocks.length);
    } on Object catch (e) {
      return EquityListFailed(e);
    }
  }

  /// Fetches the latest bhavcopy if the stored one is older than the
  /// expected latest trading day.
  ///
  /// - [force] ("Download now") skips the up-to-date, once-per-IST-day and
  ///   not-published-yet checks.
  /// - [automatic] (app open/resume) is throttled: after today's file was
  ///   found not published, it re-checks at most once per [pendingRetry].
  ///
  /// A 404 for *today's* file means "not published yet": earlier days are
  /// still walked back to as usual, but the run does not count as the day's
  /// download, so today's file is retried later.
  Future<RefreshOutcome> refreshPrices({
    bool force = false,
    bool automatic = false,
  }) async {
    DateTime? stored;
    try {
      final now = clock();
      final view = await settings.read();
      stored = view.lastFileTradeDate;
      final today = istDate(now);
      final target = expectedLatestTradingDay(now);

      if (!force) {
        if (stored != null && !stored.isBefore(target)) return UpToDate(stored);
        if (view.lastSuccessIstDate == today) {
          return AlreadyDownloadedToday(stored);
        }
        final checkedAt = view.todayPendingCheckedAt;
        if (automatic &&
            target == today &&
            checkedAt != null &&
            istDate(checkedAt) == today &&
            now.difference(checkedAt) < pendingRetry) {
          return NotPublishedYet(stored, checkedAt.add(pendingRetry));
        }
      }

      var day = target;
      DailyFile? file;
      var attempts = 0;
      var todayPending = false;
      while (attempts < maxAttempts) {
        // Walking back onto a day we already have cannot give anything new.
        if (!force && stored != null && !day.isAfter(stored)) break;
        attempts++;
        try {
          file = await provider.fetchForDate(day);
          break;
        } on PriceNotFound {
          if (day == today) todayPending = true;
          day = previousWeekday(day);
        }
      }

      final pendingKey = {
        SettingKeys.todayPendingCheckedAt: todayPending
            ? now.toUtc().toIso8601String()
            : null,
      };
      if (file == null) {
        final RefreshOutcome outcome = todayPending
            ? NotPublishedYet(stored, now.add(pendingRetry))
            : NoNewFile(attempts, stored);
        await settings.setAll({
          ...pendingKey,
          SettingKeys.lastRefreshError: null,
          SettingKeys.lastRefreshMessage: outcome.message,
        });
        return outcome;
      }

      final matched = await _store(file, now);
      final outcome = Downloaded(
        file,
        attempts,
        matched,
        todayPending: todayPending,
      );
      final newest = stored != null && stored.isAfter(file.tradeDate)
          ? stored
          : file.tradeDate;
      await settings.setAll({
        ...pendingKey,
        SettingKeys.lastFileTradeDate: dateKey(newest),
        // An earlier day's file fetched while today's is unpublished is not
        // the day's download; today's file is retried later.
        if (!todayPending) SettingKeys.lastSuccessIstDate: dateKey(today),
        SettingKeys.lastFileFetchedAt: now.toUtc().toIso8601String(),
        SettingKeys.lastFileSize: '${file.sizeBytes}',
        SettingKeys.lastRowsParsed: '${file.rowsParsed}',
        SettingKeys.lastSeriesCounts: jsonEncode(file.seriesCounts),
        SettingKeys.lastKeptSeriesCounts: jsonEncode(file.keptSeriesCounts),
        SettingKeys.lastHoldingsMatched: '$matched',
        SettingKeys.publishLog: jsonEncode(
          appendPublishLog(view.publishLog, _publishEntry(file, now)),
        ),
        SettingKeys.lastRefreshError: null,
        SettingKeys.lastRefreshMessage: outcome.message,
      });
      return outcome;
    } on Object catch (e) {
      final failed = RefreshFailed(e, stored);
      try {
        await settings.setAll({
          SettingKeys.lastRefreshError: failed.detail,
          SettingKeys.lastRefreshMessage: failed.message,
        });
      } on Object {
        // Even the error could not be recorded; the outcome still reports it.
      }
      return failed;
    }
  }

  PublishLogEntry _publishEntry(DailyFile file, DateTime now) =>
      PublishLogEntry(
        tradeDate: file.tradeDate,
        fetchedAt: now,
        source: provider.label,
        lastModified: file.serverLastModified,
        zipEntryTime: file.zipEntryTime,
      );

  Future<int> _store(DailyFile file, DateTime now) async {
    final held = await holdings.heldInstrumentIdsByIsin();
    final matched = await prices.upsertFileQuotes(file, held, now);
    await symbols.replaceFromBhavcopy([
      for (final row in file.rows)
        SymbolEntry(
          isin: row.isin,
          symbol: row.symbol,
          name: row.name,
          type: row.type,
          series: row.series,
        ),
    ]);
    final raw = file.rawZip;
    if (raw != null) await cache.write(raw);
    return matched;
  }

  /// The latest downloaded file from the on-device cache, or null.
  Future<DailyFile?> readCachedFile() async {
    try {
      final bytes = await cache.read();
      if (bytes == null) return null;
      return await runParse(parseBhavcopyZip, bytes, useIsolate: useIsolate);
    } on Object {
      return null;
    }
  }

  /// Stores the cached file's quote for a newly held instrument so it is
  /// valued straight away. Returns whether a quote was found.
  Future<bool> backfillQuote(int instrumentId, String isin) async {
    final file = await readCachedFile();
    if (file == null) return false;
    final matched = await prices.upsertFileQuotes(file, {
      isin: instrumentId,
    }, clock());
    return matched > 0;
  }

  /// "Clear cache": forget downloaded prices and file bookkeeping. Holdings,
  /// manual prices, the symbol list and the mode are kept.
  Future<void> clearCache() async {
    await prices.clearFileQuotes();
    await cache.clear();
    await settings.setAll({for (final k in SettingKeys.fileKeys) k: null});
  }
}
