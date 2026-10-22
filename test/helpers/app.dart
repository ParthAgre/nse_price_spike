import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/main.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/providers/database_providers.dart';
import 'package:nse_price_spike/providers/service_providers.dart';
import 'package:nse_price_spike/repositories/fixed_deposit_repository.dart';
import 'package:nse_price_spike/repositories/holdings_repository.dart';
import 'package:nse_price_spike/repositories/instrument_repository.dart';
import 'package:nse_price_spike/repositories/price_repository.dart';
import 'package:nse_price_spike/services/file_cache.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';
import 'package:nse_price_spike/utils/money.dart';

import 'fixtures.dart';
import 'test_database.dart';

/// 21 Oct 2026, 20:00 IST: the fixture file counts as today's.
final appNow = ist(2026, 10, 21, 20);

/// Pumps the whole app on a fresh in-memory database at 360 dp wide
/// ([logicalHeight] dp tall; list-order tests use more so every row is built),
/// after running [seed] against that database. Refresh-on-open then loads
/// the fixture files. Call [unmountApp] at the end of the test.
Future<AppDatabase> pumpApp(
  WidgetTester tester,
  FixtureLoader loader, {
  Future<void> Function(AppDatabase db)? seed,
  double logicalHeight = 800,
}) async {
  tester.view.physicalSize = Size(720, logicalHeight * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final db = createTestDatabase();
  if (seed != null) await tester.runAsync(() => seed(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        fixtureLoaderProvider.overrideWithValue(loader),
        fileCacheProvider.overrideWithValue(MemoryFileCache()),
        useIsolateProvider.overrideWithValue(false),
        clockProvider.overrideWithValue(() => appNow),
      ],
      child: const NsePriceSpikeApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Disposes providers (and the database) inside the test.
Future<void> unmountApp(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

/// Seeds an opening position of [qty] at [avgRupees].
Future<void> seedHolding(
  AppDatabase db, {
  required String isin,
  required String symbol,
  required String name,
  InstrumentType type = InstrumentType.stock,
  required int qty,
  required String avgRupees,
}) async {
  final instrument = await InstrumentRepository(
    db,
  ).upsert(SymbolEntry(isin: isin, symbol: symbol, name: name, type: type));
  await HoldingsRepository(db, PriceRepository(db)).addEntry(
    instrumentId: instrument.id,
    quantityScaled: qty * quantityScale,
    pricePaise: parseDecimalToPaise(avgRupees),
    feesPaise: 0,
    date: null,
    now: appNow,
  );
}

Future<int> seedFd(AppDatabase db, FdDraft draft) =>
    FixedDepositRepository(db).add(draft, now: appNow);

/// Taps [finder] after scrolling it into view in the first scrollable.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  // "Found" can still mean built in the cache area below the screen.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Picks a date in an open Material date picker by typing it (en_US
/// MM/DD/YYYY input mode).
Future<void> typeDateInPicker(WidgetTester tester, String mmddyyyy) async {
  await tester.tap(find.byIcon(Icons.edit_outlined).last);
  await tester.pumpAndSettle();
  final input = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(input, mmddyyyy);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

String textOf(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  return switch (widget) {
    Text(:final data) => data!,
    _ => throw StateError('not a Text: $widget'),
  };
}
