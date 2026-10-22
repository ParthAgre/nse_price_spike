import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

import '../helpers/fixtures.dart';

void main() {
  group('expectedLatestTradingDay', () {
    // 2026-10-21 is a Wednesday.
    test('weekday before 17:00 IST → previous weekday', () {
      expect(
        expectedLatestTradingDay(ist(2026, 10, 21, 16, 59)),
        d('2026-10-20'),
      );
    });

    test('weekday at 17:00 IST → today', () {
      expect(
        expectedLatestTradingDay(ist(2026, 10, 21, 17, 0)),
        d('2026-10-21'),
      );
    });

    test('weekday after 17:00 IST → today', () {
      expect(
        expectedLatestTradingDay(ist(2026, 10, 21, 23, 30)),
        d('2026-10-21'),
      );
    });

    test('just after midnight IST is still the next day', () {
      // 00:30 IST Thursday is 19:00 UTC Wednesday.
      expect(
        expectedLatestTradingDay(ist(2026, 10, 22, 0, 30)),
        d('2026-10-21'),
      );
    });

    test('Saturday → Friday, at any time', () {
      expect(expectedLatestTradingDay(ist(2026, 10, 24, 10)), d('2026-10-23'));
      expect(expectedLatestTradingDay(ist(2026, 10, 24, 21)), d('2026-10-23'));
    });

    test('Sunday → Friday', () {
      expect(expectedLatestTradingDay(ist(2026, 10, 25, 20)), d('2026-10-23'));
    });

    test('Monday morning → previous Friday', () {
      expect(expectedLatestTradingDay(ist(2026, 10, 26, 9)), d('2026-10-23'));
    });

    test('Monday 17:00 → Monday', () {
      expect(expectedLatestTradingDay(ist(2026, 10, 26, 17)), d('2026-10-26'));
    });
  });

  test('previousWeekday skips weekends', () {
    expect(previousWeekday(d('2026-10-26')), d('2026-10-23'));
    expect(previousWeekday(d('2026-10-21')), d('2026-10-20'));
  });

  test('date keys round-trip', () {
    expect(dateKey(d('2026-10-01')), '2026-10-01');
    expect(yyyymmdd(d('2026-10-01')), '20261001');
    expect(parseDateKey('2026-13-x'), isNull);
    expect(formatDisplayDate(d('2026-10-21')), '21 Oct 2026');
  });

  test('istDate uses the IST calendar day', () {
    expect(istDate(DateTime.utc(2026, 10, 21, 18, 31)), d('2026-10-22'));
    expect(istDate(DateTime.utc(2026, 10, 21, 18, 29)), d('2026-10-21'));
  });
}
