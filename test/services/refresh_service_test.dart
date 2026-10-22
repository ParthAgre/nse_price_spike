import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/repositories/holdings_repository.dart';
import 'package:nse_price_spike/repositories/instrument_repository.dart';
import 'package:nse_price_spike/repositories/price_repository.dart';
import 'package:nse_price_spike/repositories/settings_repository.dart';
import 'package:nse_price_spike/repositories/symbol_master_repository.dart';
import 'package:nse_price_spike/services/file_cache.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';
import 'package:nse_price_spike/services/refresh_service.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

const relianceIsin = 'INE002A01018';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late PriceRepository prices;
  late HoldingsRepository holdings;
  late SymbolMasterRepository symbols;
  late InstrumentRepository instruments;
  late MemoryFileCache cache;
  late DateTime now;
  late int relianceId;

  RefreshService serviceWith(ScriptedPriceProvider provider) => RefreshService(
    provider: provider,
    settings: settings,
    holdings: holdings,
    prices: prices,
    symbols: symbols,
    cache: cache,
    clock: () => now,
    useIsolate: false,
  );

  setUp(() async {
    db = createTestDatabase();
    settings = SettingsRepository(db);
    prices = PriceRepository(db);
    holdings = HoldingsRepository(db, prices);
    symbols = SymbolMasterRepository(db);
    instruments = InstrumentRepository(db);
    cache = MemoryFileCache();
    now = ist(2026, 10, 21, 20); // Wednesday, after 19:00 IST

    final reliance = await instruments.upsert(
      const SymbolEntry(
        isin: relianceIsin,
        symbol: 'RELIANCE',
        name: 'Reliance Industries Limited',
        type: InstrumentType.stock,
      ),
    );
    relianceId = reliance.id;
    await holdings.addEntry(
      instrumentId: relianceId,
      quantityScaled: 100000,
      pricePaise: 110000,
      feesPaise: 0,
      date: null,
      now: now,
    );
  });

  tearDown(() => db.close());

  Future<List<PriceQuote>> storedQuotes() => prices.quotesFor([relianceId]);

  group('download', () {
    test(
      'fetches the expected day and stores quotes only for held ISINs',
      () async {
        final provider = ScriptedPriceProvider({
          d('2026-10-21'): fixtureDailyFile(),
        });
        final outcome = await serviceWith(provider).refreshPrices();

        expect(outcome, isA<Downloaded>());
        expect(provider.requested, [d('2026-10-21')]);
        expect((outcome as Downloaded).holdingsMatched, 1);

        final quotes = await db.select(db.priceQuotes).get();
        expect(quotes, hasLength(1), reason: 'only RELIANCE is held');
        expect(quotes.single.closePaise, 120900);
        expect(quotes.single.prevClosePaise, 120200);
        expect(quotes.single.tradeDate, '2026-10-21');
        expect(quotes.single.source, 'nse_bhavcopy');

        final view = await settings.read();
        expect(view.lastFileTradeDate, d('2026-10-21'));
        expect(view.lastSuccessIstDate, d('2026-10-21'));
        expect(view.lastHoldingsMatched, 1);
        expect(view.lastRowsParsed, 3708);
        expect(view.lastSeriesCounts.first.key, 'EQ');
        expect(await cache.read(), isNotNull);
      },
    );

    test('refreshes ETF entries in symbol_master from the file', () async {
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): fixtureDailyFile(),
      });
      await serviceWith(provider).refreshPrices();
      final all = await symbols.watchAll().first;
      expect(all.where((e) => e.type == InstrumentType.etf).length, 353);
      expect(all.any((e) => e.symbol == 'NIFTYBEES'), isTrue);
    });

    test('before 19:00 IST the previous weekday is requested', () async {
      now = ist(2026, 10, 21, 18, 59);
      final provider = ScriptedPriceProvider({
        d('2026-10-20'): dailyFileFor(d('2026-10-20')),
      });
      await serviceWith(provider).refreshPrices();
      expect(provider.requested, [d('2026-10-20')]);
    });

    test('stored trade date comes from the file, not the request', () async {
      // Live NSE could serve a file whose TradDt differs from the URL date.
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): dailyFileFor(d('2026-10-20')),
      });
      await serviceWith(provider).refreshPrices();
      expect((await settings.read()).lastFileTradeDate, d('2026-10-20'));
    });
  });

  group('holiday fallback', () {
    test('404 for two days, then a file', () async {
      final provider = ScriptedPriceProvider({
        d('2026-10-19'): dailyFileFor(d('2026-10-19')),
      });
      final outcome = await serviceWith(provider).refreshPrices();

      expect(provider.requested, [
        d('2026-10-21'),
        d('2026-10-20'),
        d('2026-10-19'),
      ]);
      expect((outcome as Downloaded).attempts, 3);
      expect((await settings.read()).lastFileTradeDate, d('2026-10-19'));
    });

    test('walks back over the weekend', () async {
      now = ist(2026, 10, 26, 9); // Monday morning → target Friday 23rd
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): dailyFileFor(d('2026-10-21')),
      });
      await serviceWith(provider).refreshPrices();
      expect(provider.requested, [
        d('2026-10-23'),
        d('2026-10-22'),
        d('2026-10-21'),
      ]);
    });

    test('gives up after 5 tries', () async {
      final provider = ScriptedPriceProvider();
      final outcome = await serviceWith(provider).refreshPrices();

      expect(outcome, isA<NoNewFile>());
      expect((outcome as NoNewFile).attempts, RefreshService.maxAttempts);
      expect(provider.requested, [
        d('2026-10-21'),
        d('2026-10-20'),
        d('2026-10-19'),
        d('2026-10-16'),
        d('2026-10-15'),
      ]);
      final view = await settings.read();
      expect(view.lastSuccessIstDate, isNull, reason: '404s are not a success');
      expect(view.lastRefreshError, isNull, reason: '404s are not an error');
    });

    test('a 6th day would have had a file but is never requested', () async {
      final provider = ScriptedPriceProvider({
        d('2026-10-14'): dailyFileFor(d('2026-10-14')),
      });
      final outcome = await serviceWith(provider).refreshPrices();
      expect(outcome, isA<NoNewFile>());
      expect(provider.requested, hasLength(5));
    });

    test('stops walking back at the already-stored day', () async {
      await serviceWith(
        ScriptedPriceProvider({d('2026-10-21'): fixtureDailyFile()}),
      ).refreshPrices();

      now = ist(2026, 10, 23, 20); // Friday; 22nd and 23rd not published
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): fixtureDailyFile(),
      });
      final outcome = await serviceWith(provider).refreshPrices();

      expect(outcome, isA<NoNewFile>());
      expect(provider.requested, [d('2026-10-23'), d('2026-10-22')]);
    });
  });

  group('once per IST day', () {
    test('a second refresh the same day does not download again', () async {
      now = ist(2026, 10, 22, 20); // Thursday; today's file is late (404)
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): fixtureDailyFile(),
      });
      final service = serviceWith(provider);

      expect(await service.refreshPrices(), isA<Downloaded>());
      expect(provider.requested, [d('2026-10-22'), d('2026-10-21')]);

      now = ist(2026, 10, 22, 22);
      expect(await service.refreshPrices(), isA<AlreadyDownloadedToday>());
      expect(provider.requested, hasLength(2), reason: 'no new request');
    });

    test('"Download now" (force) bypasses the daily limit', () async {
      now = ist(2026, 10, 22, 20);
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): fixtureDailyFile(),
      });
      final service = serviceWith(provider);
      await service.refreshPrices();

      provider.byDay[d('2026-10-22')] = dailyFileFor(d('2026-10-22'));
      final outcome = await service.refreshPrices(force: true);
      expect(outcome, isA<Downloaded>());
      expect((await settings.read()).lastFileTradeDate, d('2026-10-22'));
    });

    test('the next IST day downloads again', () async {
      now = ist(2026, 10, 22, 20);
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): fixtureDailyFile(),
      });
      final service = serviceWith(provider);
      await service.refreshPrices();

      now = ist(2026, 10, 23, 20);
      provider.byDay[d('2026-10-23')] = dailyFileFor(d('2026-10-23'));
      expect(await service.refreshPrices(), isA<Downloaded>());
    });

    test('up to date when the stored file is the expected day', () async {
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): fixtureDailyFile(),
      });
      final service = serviceWith(provider);
      await service.refreshPrices();
      expect(await service.refreshPrices(), isA<UpToDate>());
      expect(provider.requested, hasLength(1));
    });
  });

  group('failures keep cached prices', () {
    for (final error in <PriceFetchException>[
      const PriceForbidden('u'),
      const PriceTimeout('u'),
      const PriceNotAZip('Ticker Not Found.'),
      const PriceParseFailure('bad'),
      const PriceNetworkFailure('offline'),
    ]) {
      test('${error.runtimeType}', () async {
        await serviceWith(
          ScriptedPriceProvider({d('2026-10-21'): fixtureDailyFile()}),
        ).refreshPrices();

        now = ist(2026, 10, 22, 20);
        final outcome = await serviceWith(
          ScriptedPriceProvider({d('2026-10-22'): error}),
        ).refreshPrices();

        expect(outcome, isA<RefreshFailed>());
        expect(
          outcome.message,
          "Couldn't reach NSE — prices as of 21 Oct 2026",
        );
        expect((await storedQuotes()).single.closePaise, 120900);
        final view = await settings.read();
        expect(view.lastRefreshError, error.message);
        expect(view.lastFileTradeDate, d('2026-10-21'));
      });
    }

    test('an error does not walk back to earlier days', () async {
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): const PriceForbidden('u'),
        d('2026-10-20'): dailyFileFor(d('2026-10-20')),
      });
      await serviceWith(provider).refreshPrices();
      expect(provider.requested, [d('2026-10-21')]);
    });

    test('unexpected exceptions never escape', () async {
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): StateError('boom'),
      });
      final outcome = await serviceWith(provider).refreshPrices();
      expect(outcome, isA<RefreshFailed>());
      expect(outcome.message, "Couldn't reach NSE — no prices yet");
    });

    test('a later success clears the error', () async {
      await serviceWith(
        ScriptedPriceProvider({d('2026-10-21'): const PriceForbidden('u')}),
      ).refreshPrices();
      expect((await settings.read()).lastRefreshError, isNotNull);
      await serviceWith(
        ScriptedPriceProvider({d('2026-10-21'): fixtureDailyFile()}),
      ).refreshPrices();
      expect((await settings.read()).lastRefreshError, isNull);
    });
  });

  group('manual price vs file', () {
    Future<EffectivePrice?> effective() async =>
        selectEffectivePrice(await storedQuotes());

    test('a file with the same trade date does not override manual', () async {
      await prices.setManualPrice(
        instrumentId: relianceId,
        closePaise: 125000,
        tradeDate: d('2026-10-21'),
        now: now,
      );
      await serviceWith(
        ScriptedPriceProvider({d('2026-10-21'): fixtureDailyFile()}),
      ).refreshPrices();
      expect((await effective())!.closePaise, 125000);
    });

    test('a newer file overrides manual', () async {
      await prices.setManualPrice(
        instrumentId: relianceId,
        closePaise: 125000,
        tradeDate: d('2026-10-20'),
        now: now,
      );
      await serviceWith(
        ScriptedPriceProvider({d('2026-10-21'): fixtureDailyFile()}),
      ).refreshPrices();
      final p = (await effective())!;
      expect(p.closePaise, 120900);
      expect(p.source, QuoteSource.nseBhavcopy);
    });
  });

  group('EQUITY_L', () {
    test('downloaded on first run, then skipped within a week', () async {
      final provider = ScriptedPriceProvider();
      final service = serviceWith(provider);

      expect(await service.refreshEquityList(), isA<EquityListUpdated>());
      expect(await symbols.count(), 2606);

      now = now.add(const Duration(days: 6));
      expect(await service.refreshEquityList(), isA<EquityListSkipped>());

      now = now.add(const Duration(days: 1));
      expect(await service.refreshEquityList(), isA<EquityListUpdated>());
      expect(provider.equityListCalls, 2);
    });

    test('forced re-download ignores the weekly limit', () async {
      final provider = ScriptedPriceProvider();
      final service = serviceWith(provider);
      await service.refreshEquityList();
      await service.refreshEquityList(force: true);
      expect(provider.equityListCalls, 2);
    });

    test('stocks and ETFs coexist in symbol_master', () async {
      final provider = ScriptedPriceProvider({
        d('2026-10-21'): fixtureDailyFile(),
      });
      final service = serviceWith(provider);
      await service.refreshPrices();
      await service.refreshEquityList();
      expect(await symbols.count(), 2606 + 353);
    });

    test('a failure is reported, not thrown', () async {
      final provider = ScriptedPriceProvider()
        ..equityListError = const PriceForbidden('u');
      expect(
        await serviceWith(provider).refreshEquityList(),
        isA<EquityListFailed>(),
      );
    });
  });

  group('cache', () {
    test('backfills a newly added holding from the cached file', () async {
      final service = serviceWith(
        ScriptedPriceProvider({d('2026-10-21'): fixtureDailyFile()}),
      );
      await service.refreshPrices();

      final bees = await instruments.upsert(
        const SymbolEntry(
          isin: 'INF204KB14I2',
          symbol: 'NIFTYBEES',
          name: 'NIP IND ETF NIFTY BEES',
          type: InstrumentType.etf,
        ),
      );
      expect(await service.backfillQuote(bees.id, bees.isin), isTrue);
      final quotes = await prices.quotesFor([bees.id]);
      expect(quotes.single.closePaise, 25957);
    });

    test(
      'clear cache removes file prices and bookkeeping, keeps manual',
      () async {
        final service = serviceWith(
          ScriptedPriceProvider({d('2026-10-21'): fixtureDailyFile()}),
        );
        await service.refreshPrices();
        await prices.setManualPrice(
          instrumentId: relianceId,
          closePaise: 1,
          tradeDate: d('2026-10-20'),
          now: now,
        );

        await service.clearCache();

        final quotes = await storedQuotes();
        expect(quotes.single.source, QuoteSource.manual);
        expect(await cache.read(), isNull);
        final view = await settings.read();
        expect(view.lastFileTradeDate, isNull);
        expect(view.lastSuccessIstDate, isNull);
      },
    );
  });

  test('holdings are derived, valued at the effective price', () async {
    await serviceWith(
      ScriptedPriceProvider({d('2026-10-21'): fixtureDailyFile()}),
    ).refreshPrices();
    final h = (await holdings.loadHoldings()).single;
    expect(h.valuePaise, 1209000);
    expect(h.pnlPaise, 109000);
    expect(h.dayChangePaise, 7000);
    expect(h.averageCostPaise, 110000);
  });
}
