import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/repositories/fixed_deposit_repository.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';

import '../helpers/app.dart';
import '../helpers/fixtures.dart';

/// ₹1,00,000 at 7%, quarterly, 1 Jan 2025 → 1 Jan 2026: matured on
/// 21 Oct 2026 with ₹1,07,185.90.
Future<void> seedMatured(AppDatabase db) => seedFd(
  db,
  FdDraft(
    institution: 'SBI',
    principalPaise: 10000000,
    rateMilliPct: 7000,
    startDate: d('2025-01-01'),
    maturityDate: d('2026-01-01'),
  ),
);

/// Same terms, 1 Jan 2026 → 1 Jan 2027: active on 21 Oct 2026.
Future<void> seedActive(AppDatabase db) => seedFd(
  db,
  FdDraft(
    institution: 'SBI',
    principalPaise: 10000000,
    rateMilliPct: 7000,
    startDate: d('2026-01-01'),
    maturityDate: d('2027-01-01'),
  ),
);

String fieldText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

void main() {
  late FixtureLoader loader;

  setUpAll(() => loader = memoryFixtureLoader());

  testWidgets('matured FD → Renewed → new FD prefilled, old one Closed', (
    tester,
  ) async {
    final db = await pumpApp(tester, loader, seed: seedMatured);

    final prompt = find.byKey(const Key('maturedPrompt-1'));
    expect(prompt, findsOneWidget);
    expect(
      find.descendant(of: prompt, matching: find.text('Renewed or withdrawn?')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: prompt, matching: find.text('Matured')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('renewed-1')));
    await tester.pumpAndSettle();

    // Prefilled: principal = maturity amount, start = old maturity date,
    // same bank; rate and tenure carried over for the user to confirm.
    expect(find.text('Renew fixed deposit'), findsOneWidget);
    expect(fieldText(tester, 'fdInstitutionField'), 'SBI');
    expect(fieldText(tester, 'fdPrincipalField'), '107185.90');
    expect(find.text('Start date: 1 Jan 2026'), findsOneWidget);
    expect(fieldText(tester, 'fdRateField'), '7');
    expect(fieldText(tester, 'fdYearsField'), '1');

    // The user confirms a new rate.
    await tester.enterText(find.byKey(const Key('fdRateField')), '6.5');
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.byKey(const Key('fdSaveButton')));

    expect(find.byKey(const Key('maturedPrompt-1')), findsNothing);
    expect(find.byKey(const Key('fdRow-2')), findsOneWidget);
    await scrollAndTap(tester, find.byKey(const Key('closedSection')));
    final closedRow = find.byKey(const Key('closedRow-1'));
    expect(closedRow, findsOneWidget);
    expect(
      find.descendant(
        of: closedRow,
        matching: find.text('Renewed on 1 Jan 2026'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: closedRow, matching: find.text('+₹7,185.90')),
      findsOneWidget,
    );

    final stored = await tester.runAsync(
      () => FixedDepositRepository(db).all(),
    );
    final byId = {for (final fd in stored!) fd.id: fd};
    expect(byId[1]!.closure, FdClosure.renewed);
    expect(byId[1]!.renewedIntoId, 2);
    expect(byId[2]!.principalPaise, 10718590);
    expect(byId[2]!.draft.rateMilliPct, 6500);
    expect(byId[2]!.startDate, d('2026-01-01'));
    expect(byId[2]!.maturityDate, d('2027-01-01'));
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('close early → realised interest shown', (tester) async {
    await pumpApp(tester, loader, seed: seedActive);

    await tester.tap(find.byKey(const Key('fdRow-1')));
    await tester.pumpAndSettle();
    // 293 of 365 days: 1e7 × 1.0175^(4 × 293/365).
    expect(find.text('293 of 365 days'), findsOneWidget);

    await scrollAndTap(tester, find.byKey(const Key('fdCloseEarly')));
    await tester.enterText(
      find.byKey(const Key('amountReceivedField')),
      '103000',
    );
    await tester.tap(find.byKey(const Key('closeConfirm')));
    await tester.pumpAndSettle();

    expect(
      textOf(
        tester,
        find.descendant(
          of: find.byKey(const Key('fdRealisedInterest')),
          matching: find.byType(Text),
        ),
      ),
      '+₹3,000.00',
    );
    expect(find.text('Closed early on 21 Oct 2026'), findsOneWidget);

    // Back on the list: out of the totals, into Closed.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fdRow-1')), findsNothing);
    expect(find.text('Closed (1)'), findsOneWidget);
    expect(find.text('Track your investments'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('matured FD → Withdrawn (default = maturity amount)', (
    tester,
  ) async {
    await pumpApp(tester, loader, seed: seedMatured);
    await tester.tap(find.byKey(const Key('withdrawn-1')));
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'amountReceivedField'), '107185.90');
    expect(find.text('Date: 1 Jan 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('closeConfirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('maturedPrompt-1')), findsNothing);
    await scrollAndTap(tester, find.byKey(const Key('closedSection')));
    expect(find.text('Withdrawn on 1 Jan 2026'), findsOneWidget);
    expect(find.text('+₹7,185.90'), findsOneWidget);
    await unmountApp(tester);
  });
}
