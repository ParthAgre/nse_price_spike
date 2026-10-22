import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/utils/portfolio_math.dart';

Lot lot(int qty, int pricePaise, {int fees = 0}) =>
    Lot(quantityScaled: qty * 10000, pricePaise: pricePaise, feesPaise: fees);

void main() {
  group('one buy', () {
    final lots = [lot(10, 110000)];

    test('invested, avg cost, value, P&L, day change', () {
      expect(investedPaise(lots), 1100000);
      expect(averageCostPaise(lots), 110000);
      expect(marketValuePaise(100000, 120900), 1209000);
      expect(unrealisedPnlPaise(1209000, 1100000), 109000);
      expect(dayChangePaise(100000, 120900, 120200), 7000);
    });
  });

  group('multiple buys', () {
    final lots = [lot(10, 100000), lot(30, 120000)];

    test('avg cost is quantity-weighted', () {
      expect(totalQuantityScaled(lots), 400000);
      expect(investedPaise(lots), 1000000 + 3600000);
      // (10×1000 + 30×1200) / 40 = 1150.00
      expect(averageCostPaise(lots), 115000);
    });

    test('avg cost rounds half away from zero to the paisa', () {
      // (1×100.00 + 2×100.01) / 3 = 100.00666… → 100.01
      expect(averageCostPaise([lot(1, 10000), lot(2, 10001)]), 10001);
    });
  });

  group('fees', () {
    final lots = [lot(10, 100000, fees: 2000), lot(10, 120000, fees: 2500)];

    test('fees count in invested', () {
      expect(investedPaise(lots), 2200000 + 4500);
    });

    test('fees are excluded from avg cost', () {
      expect(averageCostPaise(lots), 110000);
    });

    test('fees reduce P&L', () {
      final h = HoldingFigures(
        quantityScaled: 200000,
        investedPaise: investedPaise(lots),
        closePaise: 110000,
      );
      expect(h.pnlPaise, -4500);
    });
  });

  test('missing prev close gives no day change', () {
    expect(dayChangePaise(100000, 120900, null), isNull);
    final totals = computeTotals([
      const HoldingFigures(
        quantityScaled: 100000,
        investedPaise: 1100000,
        closePaise: 120900,
      ),
    ]);
    expect(totals.dayChangePaise, 0);
    expect(totals.dayChangeFraction, isNull);
    expect(totals.valuePaise, 1209000);
  });

  test('fractional ETF quantity', () {
    // 1.5 units × ₹259.57 = ₹389.355 → ₹389.36
    expect(marketValuePaise(15000, 25957), 38936);
  });

  test('empty portfolio', () {
    final totals = computeTotals(const []);
    expect(totals.valuePaise, 0);
    expect(totals.investedPaise, 0);
    expect(totals.pnlPaise, 0);
    expect(totals.pnlFraction, isNull);
    expect(totals.dayChangeFraction, isNull);
    expect(averageCostPaise(const []), isNull);
    expect(investedPaise(const []), 0);
  });

  test('totals over priced, unpriced and no-prev-close holdings', () {
    final totals = computeTotals(const [
      // RELIANCE 10 @ 1100, close 1209, prev 1202
      HoldingFigures(
        quantityScaled: 100000,
        investedPaise: 1100000,
        closePaise: 120900,
        prevClosePaise: 120200,
      ),
      // NIFTYBEES 100 @ 250, close 259.57, prev 261.20
      HoldingFigures(
        quantityScaled: 1000000,
        investedPaise: 2500000,
        closePaise: 25957,
        prevClosePaise: 26120,
      ),
      // No price yet
      HoldingFigures(quantityScaled: 50000, investedPaise: 50000),
    ]);
    expect(totals.valuePaise, 1209000 + 2595700);
    expect(totals.investedPaise, 1100000 + 2500000 + 50000);
    expect(totals.pnlPaise, 109000 + 95700);
    expect(totals.dayChangePaise, 7000 - 16300);
    expect(totals.unpricedCount, 1);
    expect(totals.pnlFraction, closeTo(204700 / 3600000, 1e-12));
    expect(
      totals.dayChangeFraction,
      closeTo(-9300 / (1209000 - 7000 + 2595700 + 16300), 1e-12),
    );
  });

  test('divRound', () {
    expect(divRound(5, 10), 1);
    expect(divRound(4, 10), 0);
    expect(divRound(-5, 10), -1);
    expect(divRound(-4, 10), 0);
  });
}
