import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/repositories/fixed_deposit_repository.dart';
import 'package:nse_price_spike/utils/fd_math.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

FdDraft draft({
  String institution = 'HDFC Bank',
  int principal = 10000000,
  String start = '2025-01-01',
  String maturity = '2026-01-01',
  FdInterestType type = FdInterestType.cumulative,
  int? receipt,
  int? payout,
}) => FdDraft(
  institution: institution,
  principalPaise: principal,
  rateMilliPct: 7000,
  startDate: d(start),
  maturityDate: d(maturity),
  interestType: type,
  payoutFrequency: type == FdInterestType.payout ? FdFrequency.monthly : null,
  receiptMaturityPaise: receipt,
  payoutAmountPaise: payout,
);

void main() {
  late AppDatabase db;
  late FixedDepositRepository repo;
  final now = DateTime.utc(2026, 10, 22);

  setUp(() {
    db = createTestDatabase();
    repo = FixedDepositRepository(db);
  });
  tearDown(() => db.close());

  test('round-trips every field', () async {
    final id = await repo.add(
      FdDraft(
        institution: '  SBI  ',
        nickname: 'Emergency',
        principalPaise: 5000000,
        rateMilliPct: 7125,
        startDate: d('2026-10-21'),
        maturityDate: d('2027-01-19'),
        compounding: FdFrequency.monthly,
        receiptMaturityPaise: 5088000,
        payoutAmountPaise: 999, // dropped: not a payout FD
        notes: 'Branch: Andheri',
      ),
      now: now,
    );
    final fd = (await repo.all()).single;
    expect(fd.id, id);
    expect(fd.institution, 'SBI');
    expect(fd.displayName, 'SBI · Emergency');
    expect(fd.draft.rateMilliPct, 7125);
    expect(fd.maturityDate, d('2027-01-19'));
    expect(fd.draft.compounding, FdFrequency.monthly);
    expect(fd.draft.receiptMaturityPaise, 5088000);
    expect(fd.draft.payoutAmountPaise, isNull);
    expect(fd.draft.notes, 'Branch: Andheri');
    expect(fd.closure, FdClosure.open);
  });

  test('renew closes the old FD at its maturity amount and links it', () async {
    final oldId = await repo.add(draft(), now: now);
    final old = (await repo.all()).single;
    final newId = await repo.renew(
      old,
      draft(
        principal: old.maturityAmount,
        start: '2026-01-01',
        maturity: '2027-01-01',
      ),
      now: now,
    );
    final byId = {for (final fd in await repo.all()) fd.id: fd};
    final closed = byId[oldId]!;
    expect(closed.closure, FdClosure.renewed);
    expect(closed.closedOn, d('2026-01-01'));
    expect(closed.amountReceivedPaise, 10718590);
    expect(closed.renewedIntoId, newId);
    expect(closed.realisedInterestPaise, 718590);
    expect(byId[newId]!.principalPaise, 10718590);
    expect(byId[newId]!.isClosed, isFalse);

    // Deleting the new FD clears the link.
    await repo.delete(newId);
    expect((await repo.all()).single.renewedIntoId, isNull);
  });

  test(
    'close early records the amount; realised interest can be lower',
    () async {
      final id = await repo.add(draft(maturity: '2027-01-01'), now: now);
      await repo.close(
        id,
        closure: FdClosure.closedEarly,
        closedOn: d('2026-07-01'),
        amountReceivedPaise: 10300000,
      );
      final fd = (await repo.all()).single;
      expect(fd.closure, FdClosure.closedEarly);
      expect(fd.realisedInterestPaise, 300000);
      expect(fd.valueOn(d('2026-07-01')), greaterThan(10300000));
    },
  );

  test('payout FD realised interest includes payouts received', () async {
    final id = await repo.add(
      draft(
        type: FdInterestType.payout,
        start: '2026-01-01',
        maturity: '2027-01-01',
        payout: 58000,
      ),
      now: now,
    );
    await repo.close(
      id,
      closure: FdClosure.closedEarly,
      closedOn: d('2026-04-15'),
      amountReceivedPaise: 9950000,
    );
    // 3 payouts (1 Feb, 1 Mar, 1 Apr) − ₹500 penalty.
    expect((await repo.all()).single.realisedInterestPaise, 3 * 58000 - 50000);
  });

  test('institution suggestions: most used first', () async {
    await repo.add(draft(institution: 'SBI'), now: now);
    await repo.add(draft(institution: 'HDFC Bank'), now: now);
    await repo.add(draft(institution: 'HDFC Bank'), now: now);
    expect(await repo.watchInstitutions().first, ['HDFC Bank', 'SBI']);
  });
}
