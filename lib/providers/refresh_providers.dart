import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/models/app_settings.dart';
import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/services/refresh_service.dart';
import 'package:nse_price_spike/utils/symbol_search.dart';

import 'database_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

class RefreshState {
  final bool busy;

  /// Outcome of the last run in this session (null before the first).
  final RefreshOutcome? lastOutcome;

  const RefreshState({this.busy = false, this.lastOutcome});

  RefreshState copyWith({bool? busy, RefreshOutcome? lastOutcome}) =>
      RefreshState(
        busy: busy ?? this.busy,
        lastOutcome: lastOutcome ?? this.lastOutcome,
      );
}

/// Runs refreshes in the background; the UI keeps showing cached data.
class RefreshController extends StateNotifier<RefreshState> {
  final Ref _ref;
  Future<RefreshOutcome>? _running;

  RefreshController(this._ref) : super(const RefreshState());

  Future<RefreshService> _service() async {
    final settings = _ref.read(settingsRepositoryProvider);
    final mode = (await settings.read()).mode;
    return RefreshService(
      provider: _ref.read(priceProviderFactoryProvider)(mode),
      settings: settings,
      holdings: _ref.read(holdingsRepositoryProvider),
      prices: _ref.read(priceRepositoryProvider),
      symbols: _ref.read(symbolMasterRepositoryProvider),
      cache: _ref.read(fileCacheProvider),
      clock: _ref.read(clockProvider),
      useIsolate: _ref.read(useIsolateProvider),
    );
  }

  void _setState(RefreshState next) {
    if (mounted) state = next;
  }

  /// App open/resume pass `automatic: true` (throttled re-checks while
  /// today's file is unpublished); the Refresh button and pull-to-refresh
  /// use the defaults; "Download now" uses `force: true`. Concurrent calls
  /// share one run.
  Future<RefreshOutcome> refresh({bool force = false, bool automatic = false}) {
    return _running ??= _run(
      force,
      automatic,
    ).whenComplete(() => _running = null);
  }

  Future<RefreshOutcome> _run(bool force, bool automatic) async {
    _setState(state.copyWith(busy: true));
    RefreshOutcome outcome;
    try {
      final service = await _service();
      await service.refreshEquityList();
      outcome = await service.refreshPrices(force: force, automatic: automatic);
    } on Object catch (e) {
      outcome = RefreshFailed(e, null);
    }
    if (outcome is Downloaded) _ref.invalidate(latestFileProvider);
    _setState(RefreshState(busy: false, lastOutcome: outcome));
    return outcome;
  }

  Future<EquityListOutcome> redownloadEquityList() async {
    _setState(state.copyWith(busy: true));
    try {
      return await (await _service()).refreshEquityList(force: true);
    } on Object catch (e) {
      return EquityListFailed(e);
    } finally {
      _setState(state.copyWith(busy: false));
    }
  }

  /// Gives a newly held instrument a price from the cached latest file.
  Future<bool> backfillQuote(int instrumentId, String isin) async {
    try {
      return await (await _service()).backfillQuote(instrumentId, isin);
    } on Object {
      return false;
    }
  }

  Future<void> clearCache() async {
    await (await _service()).clearCache();
    _ref.invalidate(latestFileProvider);
  }

  /// Wipes every table and the cached file; the mode returns to Fixture.
  Future<void> resetDatabase() async {
    await _ref.read(appDatabaseProvider).wipeAll();
    await _ref.read(fileCacheProvider).clear();
    _ref.invalidate(latestFileProvider);
    _setState(const RefreshState());
  }

  Future<void> setMode(PriceMode mode) =>
      _ref.read(settingsRepositoryProvider).setMode(mode);
}

final refreshControllerProvider =
    StateNotifierProvider<RefreshController, RefreshState>(
      (ref) => RefreshController(ref),
    );

/// The latest downloaded file (from the on-device cache), used to show the
/// close of instruments that are not held yet.
final latestFileProvider = FutureProvider<DailyFile?>((ref) async {
  final controller = ref.read(refreshControllerProvider.notifier);
  return (await controller._service()).readCachedFile();
});

/// Local search over symbol_master, ranked by traded value from the latest
/// cached bhavcopy. Rebuilds when the list changes or a new file arrives.
final symbolSearchIndexProvider = StreamProvider<SymbolSearchIndex>((
  ref,
) async* {
  final file = await ref.watch(latestFileProvider.future);
  final tradedValue = <String, int>{
    for (final row in file?.rows ?? const <BhavRow>[])
      if (row.tradedValuePaise != null) row.isin: row.tradedValuePaise!,
  };
  yield* ref
      .read(symbolMasterRepositoryProvider)
      .watchAll()
      .map(
        (entries) => SymbolSearchIndex(entries, tradedValueByIsin: tradedValue),
      );
});
