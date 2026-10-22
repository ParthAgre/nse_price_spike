import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';

import '../helpers/fixtures.dart';
import '../helpers/investments.dart';

void main() {
  final today = d('2026-10-21');

  // RELIANCE 10 @ 1100, close 1209 (prev 1202): value 12,090, +1,090, +70.
  final reliance = holding(
    'RELIANCE',
    id: 1,
    qty: 10,
    avgPaise: 110000,
    closePaise: 120900,
    prevClosePaise: 120200,
  );
  // NIFTYBEES 100 @ 250 + ₹20 charges, close 259.57 (prev 260.00).
  final niftybees = holding(
    'NIFTYBEES',
    id: 2,
    type: InstrumentType.etf,
    qty: 100,
    avgPaise: 25000,
    feesPaise: 2000,
    closePaise: 25957,
    prevClosePaise: 26000,
  );
  final unpriced = holding('NEWCO', id: 3, qty: 5, avgPaise: 10000);
  // Cumulative FD at maturity: value = 10718590.
  final maturedFd = fixedDeposit(
    id: 1,
    start: '2025-01-01',
    maturity: '2026-01-01',
  );
  // Payout FD with 3 payouts of ₹580 so far.
  final payoutFd = fixedDeposit(
    id: 2,
    principal: 10000000,
    start: '2026-07-01',
    maturity: '2027-07-01',
    type: FdInterestType.payout,
    payout: 58000,
  );
  final closedFd = fixedDeposit(
    id: 3,
    principal: 50000000,
    closure: FdClosure.withdrawn,
    closedOn: '2026-05-01',
    received: 51000000,
  );

  test('mixed portfolio: stocks + ETF + FDs; closed FD excluded', () {
    final s = computeInvestmentsSummary(
      [reliance, niftybees, unpriced],
      [maturedFd, payoutFd, closedFd],
      today,
    );
    // Value: 1209000 + 2595700 + 10718590 + 10000000.
    expect(s.currentValuePaise, 1209000 + 2595700 + 10718590 + 10000000);
    // Invested: 1100000 + 2502000 + 50000 (unpriced) + 2 FD principals.
    expect(s.investedPaise, 1100000 + 2502000 + 50000 + 20000000);
    // Returns: +109000 + 93700 + 718590 + 3 × 58000.
    expect(s.returnsPaise, 109000 + 93700 + 718590 + 174000);
    // Over priced invested only (the unpriced holding is left out).
    expect(
      s.returnsFraction,
      closeTo(
        (109000 + 93700 + 718590 + 174000) / (1100000 + 2502000 + 20000000),
        1e-12,
      ),
    );
    expect(s.unpricedCount, 1);
  });

  test('"Today" comes only from stocks and ETFs', () {
    final s = computeInvestmentsSummary(
      [reliance, niftybees],
      [maturedFd, payoutFd],
      today,
    );
    // 10 × (1209 − 1202) + 100 × (259.57 − 260.00) = 7000 − 4300.
    expect(s.todayPaise, 2700);
    expect(s.todayFraction, closeTo(2700 / (1202000 + 2600000), 1e-12));
  });

  test('allocation by class; held classes in display order', () {
    final s = computeInvestmentsSummary(
      [niftybees, reliance],
      [payoutFd, closedFd],
      today,
    );
    expect(s.heldClasses, [AssetClass.stocks, AssetClass.etfs, AssetClass.fds]);
    expect(s.valueByClass, {
      AssetClass.stocks: 1209000,
      AssetClass.etfs: 2595700,
      AssetClass.fds: 10000000,
    });
    final total = 1209000 + 2595700 + 10000000;
    expect(s.allocation[AssetClass.fds], closeTo(10000000 / total, 1e-12));
    expect(
      s.allocation.values.fold<double>(0, (a, b) => a + b),
      closeTo(1, 1e-12),
    );
  });

  test('only closed FDs: empty, no classes held', () {
    final s = computeInvestmentsSummary(const [], [closedFd], today);
    expect(s.isEmpty, isTrue);
    expect(s.currentValuePaise, 0);
    expect(s.returnsFraction, isNull);
    expect(s.allocation, isEmpty);
  });

  test('FD returns % = interest so far / principal', () {
    final item = FdItem(maturedFd, today);
    expect(item.returnsPaise, 718590);
    expect(item.returnsFraction, closeTo(0.071859, 1e-12));
    expect(item.todayFraction, isNull);
  });
}
