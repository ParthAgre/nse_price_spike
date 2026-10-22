import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';

import '../helpers/fixtures.dart';

FdStatus status(String today, {FdClosure closure = FdClosure.open}) =>
    deriveFdStatus(
      startDate: d('2026-01-01'),
      maturityDate: d('2027-01-01'),
      closure: closure,
      today: d(today),
    );

void main() {
  group('deriveFdStatus', () {
    test('upcoming before the start date', () {
      expect(status('2025-12-31'), FdStatus.upcoming);
    });

    test('active from the start date', () {
      expect(status('2026-01-01'), FdStatus.active);
      expect(status('2026-12-01'), FdStatus.active); // 31 days left
    });

    test('maturing soon within 30 days of maturity', () {
      expect(status('2026-12-02'), FdStatus.maturingSoon); // 30 days left
      expect(status('2026-12-31'), FdStatus.maturingSoon); // 1 day left
    });

    test('matured on and after the maturity date', () {
      expect(status('2027-01-01'), FdStatus.matured);
      expect(status('2028-05-01'), FdStatus.matured);
    });

    test('closed whenever a closure is stored', () {
      for (final c in [
        FdClosure.withdrawn,
        FdClosure.renewed,
        FdClosure.closedEarly,
      ]) {
        expect(status('2026-06-01', closure: c), FdStatus.closed);
        expect(status('2027-06-01', closure: c), FdStatus.closed);
      }
    });
  });

  test('FdClosure database values round-trip', () {
    for (final c in FdClosure.values) {
      expect(FdClosure.fromDb(c.dbValue), c);
    }
    expect(FdClosure.closedEarly.dbValue, 'closed_early');
  });
}
