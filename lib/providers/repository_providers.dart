import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/models/app_settings.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/repositories/holdings_repository.dart';
import 'package:nse_price_spike/repositories/instrument_repository.dart';
import 'package:nse_price_spike/repositories/price_repository.dart';
import 'package:nse_price_spike/repositories/settings_repository.dart';
import 'package:nse_price_spike/repositories/symbol_master_repository.dart';
import 'package:nse_price_spike/utils/portfolio_math.dart';

import 'database_providers.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.read(appDatabaseProvider)),
);

final instrumentRepositoryProvider = Provider<InstrumentRepository>(
  (ref) => InstrumentRepository(ref.read(appDatabaseProvider)),
);

final priceRepositoryProvider = Provider<PriceRepository>(
  (ref) => PriceRepository(ref.read(appDatabaseProvider)),
);

final holdingsRepositoryProvider = Provider<HoldingsRepository>(
  (ref) => HoldingsRepository(
    ref.read(appDatabaseProvider),
    ref.read(priceRepositoryProvider),
  ),
);

final symbolMasterRepositoryProvider = Provider<SymbolMasterRepository>(
  (ref) => SymbolMasterRepository(ref.read(appDatabaseProvider)),
);

final settingsProvider = StreamProvider<AppSettingsView>((ref) {
  return ref.read(settingsRepositoryProvider).watch();
});

/// Holdings sorted by value, largest first.
final holdingsProvider = StreamProvider<List<Holding>>((ref) {
  return ref
      .read(holdingsRepositoryProvider)
      .watchHoldings()
      .map(sortByValueDesc);
});

final portfolioTotalsProvider = Provider<AsyncValue<PortfolioTotals>>((ref) {
  return ref
      .watch(holdingsProvider)
      .whenData((holdings) => computeTotals(holdings.map((h) => h.figures)));
});

/// One holding by instrument id; null once all its entries are deleted.
final holdingProvider = Provider.family<AsyncValue<Holding?>, int>((
  ref,
  instrumentId,
) {
  return ref
      .watch(holdingsProvider)
      .whenData(
        (list) =>
            list.where((h) => h.instrument.id == instrumentId).firstOrNull,
      );
});

final quoteHistoryProvider = StreamProvider.family<List<PriceQuote>, int>((
  ref,
  instrumentId,
) {
  return ref.read(priceRepositoryProvider).watchQuotes(instrumentId);
});
