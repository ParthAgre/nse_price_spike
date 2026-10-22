import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/main.dart';
import 'package:nse_price_spike/providers/database_providers.dart';
import 'package:nse_price_spike/providers/service_providers.dart';
import 'package:nse_price_spike/services/file_cache.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

String textOf(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  return switch (widget) {
    Text(:final data) => data!,
    _ => throw StateError('not a Text: $widget'),
  };
}

void main() {
  late FixtureLoader loader;

  setUpAll(() {
    // Read files before the fake-async zone of testWidgets.
    loader = memoryFixtureLoader();
  });

  testWidgets(
    'Fixture mode: add RELIANCE → portfolio shows value and day change',
    (tester) async {
      // A 360 dp wide phone, like the target emulator.
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) {
              final db = createTestDatabase();
              ref.onDispose(db.close);
              return db;
            }),
            fixtureLoaderProvider.overrideWithValue(loader),
            fileCacheProvider.overrideWithValue(MemoryFileCache()),
            useIsolateProvider.overrideWithValue(false),
            clockProvider.overrideWithValue(() => ist(2026, 10, 21, 20)),
          ],
          child: const NsePriceSpikeApp(),
        ),
      );
      // Refresh on open: EQUITY_L + bhavcopy from fixtures.
      await tester.pumpAndSettle();

      expect(find.text('Track your investments'), findsOneWidget);

      await tester.tap(find.byKey(const Key('addButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sheetStock')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchField')), 'reli');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'RELIANCE').first);
      await tester.pumpAndSettle();

      expect(
        textOf(tester, find.byKey(const Key('latestClose'))),
        'Latest close: ₹1,209.00 (21 Oct 2026)',
      );

      await tester.enterText(find.byKey(const Key('quantityField')), '10');
      await tester.enterText(find.byKey(const Key('priceField')), '1100');
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      // Back on Investments: 10 × ₹1,209.00 (shown in whole rupees), day
      // change 10 × (1209 − 1202).
      expect(
        find.text('Market prices as of 21 Oct 2026 · FD values as of today'),
        findsOneWidget,
      );
      expect(textOf(tester, find.byKey(const Key('totalValue'))), '₹12,090');
      expect(
        textOf(
          tester,
          find.descendant(
            of: find.byKey(const Key('dayChange')),
            matching: find.byType(Text),
          ),
        ),
        '+₹70.00 (+0.58%)',
      );
      expect(find.text('+₹1,090.00 (+9.91%)'), findsWidgets);
      expect(find.text('Reliance Industries Limited'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Unmount so providers (and the database) are disposed inside the test.
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('stock quantity must be a whole number', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = createTestDatabase();
            ref.onDispose(db.close);
            return db;
          }),
          fixtureLoaderProvider.overrideWithValue(loader),
          fileCacheProvider.overrideWithValue(MemoryFileCache()),
          useIsolateProvider.overrideWithValue(false),
          clockProvider.overrideWithValue(() => ist(2026, 10, 21, 20)),
        ],
        child: const NsePriceSpikeApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sheetStock')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('searchField')), 'RELIANCE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'RELIANCE').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('quantityField')), '1.5');
    await tester.enterText(find.byKey(const Key('priceField')), '0');
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Stocks need a whole number'), findsOneWidget);
    expect(find.text('Price must be more than 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
