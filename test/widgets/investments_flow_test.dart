import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';

import '../helpers/app.dart';
import '../helpers/fixtures.dart';

const relianceIsin = 'INE002A01018';
const niftybeesIsin = 'INF204KB14I2';

/// RELIANCE 10 @ 1100 (close 1209, prev 1202), NIFTYBEES 10 @ 250 (close
/// 259.57) and a ₹1,00,000 7% FD from 1 Nov 2025 to 1 Nov 2026.
Future<void> seedMixed(AppDatabase db) async {
  await seedHolding(
    db,
    isin: relianceIsin,
    symbol: 'RELIANCE',
    name: 'Reliance Industries Limited',
    qty: 10,
    avgRupees: '1100',
  );
  await seedHolding(
    db,
    isin: niftybeesIsin,
    symbol: 'NIFTYBEES',
    name: 'Nippon India Nifty 50 BeES',
    type: InstrumentType.etf,
    qty: 10,
    avgRupees: '250',
  );
  await seedFd(
    db,
    FdDraft(
      institution: 'HDFC Bank',
      principalPaise: 10000000,
      rateMilliPct: 7000,
      startDate: d('2025-11-01'),
      maturityDate: d('2026-11-01'),
    ),
  );
}

/// Top-to-bottom order of the given row keys on screen.
List<String> rowOrder(WidgetTester tester, List<String> keys) {
  final present = keys
      .where((k) => find.byKey(Key(k)).evaluate().isNotEmpty)
      .toList();
  present.sort(
    (a, b) => tester
        .getTopLeft(find.byKey(Key(a)))
        .dy
        .compareTo(tester.getTopLeft(find.byKey(Key(b))).dy),
  );
  return present;
}

void main() {
  late FixtureLoader loader;

  setUpAll(() => loader = memoryFixtureLoader());

  testWidgets('empty state → add an FD → it appears with value and chip', (
    tester,
  ) async {
    await pumpApp(tester, loader);
    expect(find.text('Track your investments'), findsOneWidget);

    await tester.tap(find.byKey(const Key('emptyAddFd')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('fdInstitutionField')),
      'HDFC Bank',
    );
    await tester.enterText(find.byKey(const Key('fdPrincipalField')), '100000');
    await tester.enterText(find.byKey(const Key('fdRateField')), '7');
    await tester.tap(find.byKey(const Key('fdStartPick')));
    await tester.pumpAndSettle();
    await typeDateInPicker(tester, '11/01/2025');
    expect(find.text('Start date: 1 Nov 2025'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('fdYearsField')), '1');
    await tester.pumpAndSettle();

    expect(find.text('Matures on 1 Nov 2026'), findsOneWidget);
    // The required 1-year value, quarterly compounding (the default).
    expect(
      textOf(tester, find.byKey(const Key('fdPreview'))),
      'Matures 1 Nov 2026 · ₹1,07,185.90 · interest ₹7,185.90',
    );

    await scrollAndTap(tester, find.byKey(const Key('fdSaveButton')));

    // 354 of 365 days: 1e7 × 1.0175^(4 × 354/365) = 10696197 paise.
    final row = find.byKey(const Key('fdRow-1'));
    expect(row, findsOneWidget);
    expect(
      textOf(
        tester,
        find.descendant(of: row, matching: find.byKey(const Key('fdValue'))),
      ),
      '≈₹1,06,961.97',
    );
    expect(
      textOf(
        tester,
        find.descendant(of: row, matching: find.byKey(const Key('fdInterest'))),
      ),
      '+₹6,961.97',
    );
    expect(
      find.descendant(of: row, matching: find.text('Maturing soon')),
      findsOneWidget,
    );
    expect(
      find.text('₹1,00,000.00 · 7% · matures 1 Nov 2026 (11 days)'),
      findsOneWidget,
    );
    expect(textOf(tester, find.byKey(const Key('totalValue'))), '₹1,06,962');
    expect(
      find.text('No market prices yet · FD values as of today'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('add a stock with "More details" collapsed → live preview', (
    tester,
  ) async {
    await pumpApp(tester, loader);
    await tester.tap(find.byKey(const Key('addButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sheetStock')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('searchField')), 'reli');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'RELIANCE').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stockPreview')), findsNothing);
    await tester.enterText(find.byKey(const Key('quantityField')), '10');
    await tester.pump();
    // Quantity alone isn't enough for a preview.
    expect(find.byKey(const Key('stockPreview')), findsNothing);
    await tester.enterText(find.byKey(const Key('priceField')), '1100');
    await tester.pump();

    // The "More details" fields stay hidden (collapsed).
    expect(find.text('Charges (₹)'), findsNothing);
    expect(
      textOf(tester, find.byKey(const Key('stockPreview'))),
      'Invested ₹11,000 · worth ₹12,090 today (+9.91%)',
    );
    await tester.enterText(find.byKey(const Key('priceField')), '1300');
    await tester.pump();
    expect(
      textOf(tester, find.byKey(const Key('stockPreview'))),
      'Invested ₹13,000 · worth ₹12,090 today (−7.00%)',
    );
    await unmountApp(tester);
  });

  testWidgets('filter chips and the Total/Today toggle', (tester) async {
    await pumpApp(tester, loader, seed: seedMixed, logicalHeight: 1400);
    const reliance = Key('holdingRow-$relianceIsin');
    const bees = Key('holdingRow-$niftybeesIsin');
    const fd = Key('fdRow-1');

    for (final f in ['all', 'stocks', 'etfs', 'fds']) {
      expect(find.byKey(Key('filter-$f')), findsOneWidget, reason: f);
    }
    expect(find.byKey(const Key('allocationBar')), findsOneWidget);
    expect(find.byKey(reliance), findsOneWidget);
    expect(find.byKey(bees), findsOneWidget);
    expect(find.byKey(fd), findsOneWidget);

    // Total (default): RELIANCE +9.91%.
    String percentOf(Key row) => textOf(
      tester,
      find.descendant(
        of: find.byKey(row),
        matching: find.descendant(
          of: find.byKey(const Key('rowPercent')),
          matching: find.byType(Text),
        ),
      ),
    );
    expect(percentOf(reliance), '+9.91%');
    await tester.tap(find.byKey(const Key('toggleToday')));
    await tester.pumpAndSettle();
    expect(percentOf(reliance), '+0.58%');
    // FD rows are unaffected by the toggle.
    expect(
      find.descendant(of: find.byKey(fd), matching: find.text('+₹6,961.97')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('filter-etfs')));
    await tester.pumpAndSettle();
    expect(find.byKey(bees), findsOneWidget);
    expect(find.byKey(reliance), findsNothing);
    expect(find.byKey(fd), findsNothing);

    await tester.tap(find.byKey(const Key('filter-fds')));
    await tester.pumpAndSettle();
    expect(find.byKey(fd), findsOneWidget);
    expect(find.byKey(bees), findsNothing);
    expect(find.byKey(const Key('totalTodayToggle')), findsNothing);

    await tester.tap(find.byKey(const Key('filter-stocks')));
    await tester.pumpAndSettle();
    expect(find.byKey(reliance), findsOneWidget);
    expect(find.byKey(fd), findsNothing);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('sorting', (tester) async {
    await pumpApp(tester, loader, seed: seedMixed, logicalHeight: 1400);
    const keys = [
      'fdRow-1',
      'holdingRow-$relianceIsin',
      'holdingRow-$niftybeesIsin',
    ];

    Future<void> sortBy(String name) async {
      await tester.tap(find.byKey(const Key('sortButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('sort-$name')));
      await tester.pumpAndSettle();
    }

    // Default: current value (FD ₹1,06,962 > RELIANCE ₹12,090 > BeES ₹2,596).
    expect(textOf(tester, find.byKey(const Key('sortLabel'))), 'Current value');
    expect(rowOrder(tester, keys), keys);

    await sortBy('name');
    expect(rowOrder(tester, keys), [
      'fdRow-1', // HDFC Bank
      'holdingRow-$niftybeesIsin', // Nippon …
      'holdingRow-$relianceIsin', // Reliance …
    ]);

    await sortBy('returns');
    expect(rowOrder(tester, keys), [
      'holdingRow-$relianceIsin', // +9.91%
      'fdRow-1', // +6.96%
      'holdingRow-$niftybeesIsin', // +3.83%
    ]);

    await sortBy('today');
    expect(rowOrder(tester, keys).last, 'fdRow-1'); // FDs: no daily change

    // "Maturity date" is offered only under FDs, where it is the default.
    await tester.tap(find.byKey(const Key('sortButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sort-maturity')), findsNothing);
    await tester.tap(find.byKey(const Key('sort-value')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-fds')));
    await tester.pumpAndSettle();
    expect(textOf(tester, find.byKey(const Key('sortLabel'))), 'Maturity date');
    await tester.tap(find.byKey(const Key('sortButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sort-maturity')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sort-name')));
    await tester.pumpAndSettle();
    expect(textOf(tester, find.byKey(const Key('sortLabel'))), 'Name');
    await tester.tap(find.byKey(const Key('filter-all')));
    await tester.pumpAndSettle();
    expect(textOf(tester, find.byKey(const Key('sortLabel'))), 'Current value');
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('returns info icon explains returns', (tester) async {
    await pumpApp(tester, loader, seed: seedMixed, logicalHeight: 1400);
    await tester.tap(find.byKey(const Key('returnsInfo')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Returns: what your investments are worth now minus what you paid; '
        'not yet sold, before charges and tax.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await unmountApp(tester);
  });
}
