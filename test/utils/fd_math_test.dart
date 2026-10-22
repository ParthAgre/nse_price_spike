import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/utils/fd_math.dart';

import '../helpers/fixtures.dart';

void main() {
  group('dates', () {
    test('month-end clamping', () {
      expect(addMonthsClamped(d('2026-01-31'), 1), d('2026-02-28'));
      expect(addMonthsClamped(d('2028-01-31'), 1), d('2028-02-29'));
      expect(addMonthsClamped(d('2026-03-31'), 1), d('2026-04-30'));
      expect(addMonthsClamped(d('2026-10-15'), 3), d('2027-01-15'));
      expect(addMonthsClamped(d('2026-12-31'), 2), d('2027-02-28'));
    });

    test('maturity from tenure: years, months, days', () {
      expect(maturityFromTenure(d('2026-01-01'), years: 1), d('2027-01-01'));
      expect(
        maturityFromTenure(d('2026-01-31'), months: 1, days: 2),
        d('2026-03-02'),
      );
      expect(maturityFromTenure(d('2026-10-21'), days: 90), d('2027-01-19'));
    });

    test('leap years: 29 Feb + 1 year clamps to 28 Feb', () {
      expect(maturityFromTenure(d('2028-02-29'), years: 1), d('2029-02-28'));
      expect(maturityFromTenure(d('2028-02-29'), years: 4), d('2032-02-29'));
      expect(daysBetween(d('2028-01-01'), d('2029-01-01')), 366);
    });

    test('tenureBetween inverts maturityFromTenure', () {
      expect(
        tenureBetween(d('2026-01-31'), d('2026-03-02')),
        const Tenure(0, 1, 2),
      );
      expect(
        tenureBetween(d('2026-10-21'), d('2029-01-21')),
        const Tenure(2, 3, 0),
      );
      expect(
        tenureBetween(d('2026-10-21'), d('2027-01-19')),
        const Tenure(0, 2, 29),
      );
    });
  });

  group('maturity amounts (required values)', () {
    test('₹1,00,000 at 7%, quarterly, 1 year → 10718590 paise', () {
      final t = FdTerms(
        principalPaise: 10000000,
        rateMilliPct: 7000,
        startDate: d('2026-01-01'),
        maturityDate: maturityFromTenure(d('2026-01-01'), years: 1),
      );
      expect(t.usesSimpleInterest, isFalse);
      expect(estimatedMaturityPaise(t), 10718590);
      expect(maturityAmountPaise(t), 10718590);
      expect(fdInterestAtMaturityPaise(t), 718590);
    });

    test('₹50,000 at 6%, 90 days → simple interest → 5073973 paise', () {
      final start = d('2026-10-21');
      final t = FdTerms(
        principalPaise: 5000000,
        rateMilliPct: 6000,
        startDate: start,
        maturityDate: maturityFromTenure(start, days: 90),
      );
      expect(t.usesSimpleInterest, isTrue);
      expect(estimatedMaturityPaise(t), 5073973);
    });

    test('exactly 6 months is compounded; one day less is simple', () {
      final start = d('2026-01-15');
      FdTerms terms(DateTime maturity) => FdTerms(
        principalPaise: 10000000,
        rateMilliPct: 7000,
        startDate: start,
        maturityDate: maturity,
      );
      expect(terms(d('2026-07-15')).usesSimpleInterest, isFalse);
      expect(terms(d('2026-07-14')).usesSimpleInterest, isTrue);
    });

    test('compounding frequency changes the result', () {
      FdTerms terms(FdFrequency f) => FdTerms(
        principalPaise: 10000000,
        rateMilliPct: 7000,
        startDate: d('2026-01-01'),
        maturityDate: d('2027-01-01'),
        compounding: f,
      );
      expect(estimatedMaturityPaise(terms(FdFrequency.yearly)), 10700000);
      expect(
        estimatedMaturityPaise(terms(FdFrequency.monthly)),
        greaterThan(estimatedMaturityPaise(terms(FdFrequency.quarterly))),
      );
    });

    test('rate with 3 decimals (7.125%)', () {
      final t = FdTerms(
        principalPaise: 10000000,
        rateMilliPct: 7125,
        startDate: d('2026-01-01'),
        maturityDate: d('2027-01-01'),
        compounding: FdFrequency.yearly,
      );
      expect(estimatedMaturityPaise(t), 10712500);
    });

    test('rounds once, half-up', () {
      expect(roundPaise(5073972.5), 5073973);
      expect(roundPaise(5073972.4999), 5073972);
    });
  });

  group('current value (cumulative)', () {
    final start = d('2026-01-01');
    final noReceipt = FdTerms(
      principalPaise: 10000000,
      rateMilliPct: 7000,
      startDate: start,
      maturityDate: d('2027-01-01'),
    );
    final withReceipt = FdTerms(
      principalPaise: 10000000,
      rateMilliPct: 7000,
      startDate: start,
      maturityDate: d('2027-01-01'),
      receiptMaturityPaise: 10720000,
    );

    test('before the start and at the start: the principal', () {
      expect(fdValueOnPaise(noReceipt, d('2025-12-01')), 10000000);
      expect(fdValueOnPaise(noReceipt, start), 10000000);
      expect(fdValueIsApproximate(noReceipt, start), isFalse);
    });

    test('at and after maturity: the maturity amount', () {
      expect(fdValueOnPaise(noReceipt, d('2027-01-01')), 10718590);
      expect(fdValueOnPaise(noReceipt, d('2028-06-01')), 10718590);
      expect(fdValueIsApproximate(noReceipt, d('2027-01-01')), isFalse);
      expect(fdValueIsApproximate(noReceipt, d('2026-06-01')), isTrue);
    });

    test('mid-term follows the compound formula', () {
      // 181 days: 1e7 × 1.0175^(4 × 181/365).
      expect(fdValueOnPaise(noReceipt, d('2026-07-01')), 10350110);
    });

    test('receipt-calibrated curve hits M exactly at maturity', () {
      expect(maturityAmountPaise(withReceipt), 10720000);
      expect(fdValueOnPaise(withReceipt, d('2027-01-01')), 10720000);
      // The curve's last day before maturity approaches M from below.
      final dayBefore = fdValueOnPaise(withReceipt, d('2026-12-31'));
      expect(dayBefore, lessThan(10720000));
      expect(dayBefore, 10717958); // 1e7 × 1.072^(364/365)
      expect(estimatedMaturityPaise(withReceipt), 10718590);
    });

    test('value never decreases over time (all variants)', () {
      final variants = [
        noReceipt,
        withReceipt,
        FdTerms(
          principalPaise: 5000000,
          rateMilliPct: 6000,
          startDate: start,
          maturityDate: start.add(const Duration(days: 90)),
        ),
        FdTerms(
          principalPaise: 5000000,
          rateMilliPct: 6000,
          startDate: start,
          maturityDate: start.add(const Duration(days: 90)),
          receiptMaturityPaise: 5074500,
        ),
      ];
      for (final t in variants) {
        var previous = fdValueOnPaise(
          t,
          start.subtract(const Duration(days: 5)),
        );
        for (var i = -4; i <= t.totalDays + 5; i++) {
          final value = fdValueOnPaise(t, start.add(Duration(days: i)));
          expect(value, greaterThanOrEqualTo(previous), reason: 'day $i');
          previous = value;
        }
      }
    });

    test('short FD accrues linearly (simple interest)', () {
      final t = FdTerms(
        principalPaise: 5000000,
        rateMilliPct: 6000,
        startDate: start,
        maturityDate: start.add(const Duration(days: 90)),
      );
      // 45 days: 5000000 × 0.06 × 45/365 = 36986.30 → 36986.
      expect(fdValueOnPaise(t, start.add(const Duration(days: 45))), 5036986);
    });

    test('future start: value is the principal, interest zero', () {
      final t = FdTerms(
        principalPaise: 10000000,
        rateMilliPct: 7000,
        startDate: d('2026-12-01'),
        maturityDate: d('2027-12-01'),
      );
      expect(fdValueOnPaise(t, d('2026-10-22')), 10000000);
      expect(fdInterestSoFarPaise(t, d('2026-10-22')), 0);
    });
  });

  group('payout FDs', () {
    final start = d('2026-01-31');
    final monthly = FdTerms(
      principalPaise: 12000000,
      rateMilliPct: 7000,
      startDate: start,
      maturityDate: d('2027-01-31'),
      interestType: FdInterestType.payout,
      payoutFrequency: FdFrequency.monthly,
    );

    test('value is always the principal; maturity amount = principal', () {
      expect(fdValueOnPaise(monthly, d('2026-06-15')), 12000000);
      expect(maturityAmountPaise(monthly), 12000000);
      expect(fdValueIsApproximate(monthly, d('2026-06-15')), isFalse);
    });

    test('estimated payout = P × r / k; user figure wins', () {
      expect(payoutPerPeriodPaise(monthly), 70000);
      expect(payoutIsEstimated(monthly), isTrue);
      final given = FdTerms(
        principalPaise: 12000000,
        rateMilliPct: 7000,
        startDate: start,
        maturityDate: d('2027-01-31'),
        interestType: FdInterestType.payout,
        payoutAmountPaise: 69600,
      );
      expect(payoutPerPeriodPaise(given), 69600);
      expect(payoutIsEstimated(given), isFalse);
    });

    test('interest steps up only on period boundaries (month-end clamped)', () {
      // Boundaries: 28 Feb, 31 Mar, 30 Apr, …
      expect(completedPayoutPeriods(monthly, d('2026-02-27')), 0);
      expect(completedPayoutPeriods(monthly, d('2026-02-28')), 1);
      expect(completedPayoutPeriods(monthly, d('2026-03-30')), 1);
      expect(completedPayoutPeriods(monthly, d('2026-03-31')), 2);
      expect(completedPayoutPeriods(monthly, d('2027-01-31')), 12);
      expect(completedPayoutPeriods(monthly, d('2028-01-01')), 12);

      var previous = 0;
      for (var i = 0; i <= 400; i++) {
        final day = start.add(Duration(days: i));
        final received = interestReceivedPaise(monthly, day);
        expect(received, greaterThanOrEqualTo(previous));
        if (received != previous) {
          // Changes happen only on a boundary date.
          final periods = completedPayoutPeriods(monthly, day);
          expect(addMonthsClamped(start, periods), day, reason: '$day');
          expect(received - previous, 70000);
        }
        previous = received;
      }
      expect(fdInterestSoFarPaise(monthly, d('2026-06-15')), 4 * 70000);
      expect(fdInterestAtMaturityPaise(monthly), 12 * 70000);
    });

    test('quarterly payout', () {
      final quarterly = FdTerms(
        principalPaise: 10000000,
        rateMilliPct: 7000,
        startDate: d('2026-01-01'),
        maturityDate: d('2027-01-01'),
        interestType: FdInterestType.payout,
        payoutFrequency: FdFrequency.quarterly,
      );
      expect(payoutPerPeriodPaise(quarterly), 175000);
      expect(completedPayoutPeriods(quarterly, d('2026-06-30')), 1);
      expect(completedPayoutPeriods(quarterly, d('2026-07-01')), 2);
    });
  });
}
