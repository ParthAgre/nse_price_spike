import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/price_quote.dart';

import '../helpers/fixtures.dart';

PriceQuote quote(
  String date,
  int close, {
  QuoteSource source = QuoteSource.nseBhavcopy,
  int? prev,
  DateTime? fetchedAt,
}) => PriceQuote(
  instrumentId: 1,
  tradeDate: d(date),
  closePaise: close,
  prevClosePaise: prev,
  source: source,
  fetchedAt: fetchedAt ?? DateTime.utc(2026),
);

void main() {
  group('selectEffectivePrice', () {
    test('no quotes → null', () {
      expect(selectEffectivePrice(const []), isNull);
    });

    test('latest file quote wins among file quotes', () {
      final p = selectEffectivePrice([
        quote('2026-10-20', 100, prev: 90),
        quote('2026-10-21', 120, prev: 100),
      ])!;
      expect(p.closePaise, 120);
      expect(p.prevClosePaise, 100);
      expect(p.source, QuoteSource.nseBhavcopy);
    });

    test('manual price dated the same day as the file stays', () {
      final p = selectEffectivePrice([
        quote('2026-10-21', 120, prev: 100),
        quote('2026-10-21', 130, source: QuoteSource.manual),
      ])!;
      expect(p.source, QuoteSource.manual);
      expect(p.closePaise, 130);
      expect(p.prevClosePaise, isNull, reason: 'no day change for manual');
    });

    test('a strictly newer file overrides the manual price', () {
      final p = selectEffectivePrice([
        quote('2026-10-21', 130, source: QuoteSource.manual),
        quote('2026-10-22', 125, prev: 120),
      ])!;
      expect(p.source, QuoteSource.nseBhavcopy);
      expect(p.closePaise, 125);
    });

    test('an older file does not override a newer manual price', () {
      final p = selectEffectivePrice([
        quote('2026-10-20', 100),
        quote('2026-10-22', 130, source: QuoteSource.manual),
      ])!;
      expect(p.source, QuoteSource.manual);
    });

    test('latest manual entry wins on the same day', () {
      final p = selectEffectivePrice([
        quote(
          '2026-10-22',
          130,
          source: QuoteSource.manual,
          fetchedAt: DateTime.utc(2026, 10, 22, 5),
        ),
        quote(
          '2026-10-22',
          140,
          source: QuoteSource.manual,
          fetchedAt: DateTime.utc(2026, 10, 22, 6),
        ),
      ])!;
      expect(p.closePaise, 140);
    });
  });
}
