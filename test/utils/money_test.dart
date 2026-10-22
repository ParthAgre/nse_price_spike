import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/utils/money.dart';

void main() {
  group('parseDecimalToPaise (string parsing, no doubles)', () {
    test('converts bhavcopy prices exactly', () {
      expect(parseDecimalToPaise('1209.00'), 120900);
      expect(parseDecimalToPaise('259.57'), 25957);
      expect(parseDecimalToPaise('0.05'), 5);
      expect(parseDecimalToPaise('14499.99'), 1449999);
    });

    test('accepts zero, one or no decimals and surrounding spaces', () {
      expect(parseDecimalToPaise('1209'), 120900);
      expect(parseDecimalToPaise('1209.5'), 120950);
      expect(parseDecimalToPaise('1209.'), 120900);
      expect(parseDecimalToPaise('.5'), 50);
      expect(parseDecimalToPaise(' 12.34 '), 1234);
      expect(parseDecimalToPaise('0'), 0);
    });

    test('values that are inexact as doubles stay exact', () {
      // 0.29 * 100 == 28.999999999999996 in floating point.
      expect(parseDecimalToPaise('0.29'), 29);
      expect(parseDecimalToPaise('1.15'), 115);
    });

    test('rejects malformed input', () {
      for (final bad in [
        '',
        ' ',
        '.',
        '-1.00',
        '1,209.00',
        '12.345',
        'abc',
        '1e3',
      ]) {
        expect(
          () => parseDecimalToPaise(bad),
          throwsFormatException,
          reason: bad,
        );
        expect(tryParseDecimalToPaise(bad), isNull, reason: bad);
      }
    });
  });

  group('parseQuantityScaled', () {
    test('scales by 10,000', () {
      expect(parseQuantityScaled('10'), 100000);
      expect(parseQuantityScaled('1.5'), 15000);
      expect(parseQuantityScaled('0.0001'), 1);
    });

    test('rejects more than 4 decimals', () {
      expect(tryParseQuantityScaled('1.23456'), isNull);
    });
  });

  group('formatting', () {
    test('formatRupees uses Indian grouping and paise', () {
      expect(formatRupees(1209000), '₹12,090.00');
      expect(formatRupees(12345678901), '₹12,34,56,789.01');
      expect(formatRupees(5), '₹0.05');
      expect(formatRupees(-7000), '−₹70.00');
      expect(formatRupees(7000, showPlus: true), '+₹70.00');
      expect(formatRupees(0, showPlus: true), '₹0.00');
    });

    test('formatRupees: lakh and crore grouping, negatives, zero', () {
      expect(formatRupees(10718590), '₹1,07,185.90');
      expect(formatRupees(1234567890), '₹1,23,45,678.90');
      expect(formatRupees(-125000), '−₹1,250.00');
      expect(formatRupees(0), '₹0.00');
      expect(formatRupees(99999), '₹999.99');
      expect(formatRupees(100000), '₹1,000.00');
      expect(formatRupees(10000000), '₹1,00,000.00');
      expect(formatRupees(1000000000), '₹1,00,00,000.00');
    });

    test('formatRupeesWhole rounds half away from zero', () {
      expect(formatRupeesWhole(10718590), '₹1,07,186');
      expect(formatRupeesWhole(10718549), '₹1,07,185');
      expect(formatRupeesWhole(-125050), '−₹1,251');
      expect(formatRupeesWhole(1209000, showPlus: true), '+₹12,090');
      expect(formatRupeesWhole(0, showPlus: true), '₹0');
    });

    test('formatPercent: two decimals with an explicit sign', () {
      expect(formatPercent(0.0991), '+9.91%');
      expect(formatPercent(-0.0058), '−0.58%');
      expect(formatPercent(0), '0.00%');
      expect(formatPercent(-0.00001), '0.00%');
    });

    test('formatRateMilli and formatShare', () {
      expect(formatRateMilli(7125), '7.125');
      expect(formatRateMilli(7000), '7');
      expect(formatRateMilli(7500), '7.5');
      expect(formatRateMilli(650), '0.65');
      expect(formatShare(0.6243), '62.4%');
    });

    test('formatQuantity trims trailing zeros', () {
      expect(formatQuantity(100000), '10');
      expect(formatQuantity(15000), '1.5');
      expect(formatQuantity(12345678), '1,234.5678');
    });

    test('formatPercent', () {
      expect(formatPercent(0.0058), '+0.58%');
      expect(formatPercent(-0.1), '−10.00%');
      expect(formatPercent(null), '—');
    });

    test('form round-trips', () {
      expect(paiseToInput(120905), '1209.05');
      expect(quantityToInput(12345678), '1234.5678');
    });
  });
}
