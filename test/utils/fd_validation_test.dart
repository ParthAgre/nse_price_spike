import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/fd_validation.dart';
import 'package:nse_price_spike/utils/holding_validation.dart';

import '../helpers/fixtures.dart';

void main() {
  test('institution is required', () {
    expect(validateInstitution('  '), S.enterInstitution);
    expect(validateInstitution('HDFC Bank'), isNull);
  });

  test('principal > 0, up to 2 decimals', () {
    expect(validatePrincipal(''), S.enterPrincipal);
    expect(validatePrincipal('0'), S.principalPositive);
    expect(validatePrincipal('1,00,000'), S.amountFormat);
    expect(validatePrincipal('100000.555'), S.amountFormat);
    expect(validatePrincipal('100000.50'), isNull);
  });

  test('rate: 0 < rate ≤ 20, up to 3 decimals', () {
    expect(validateRate(''), S.enterRate);
    expect(validateRate('0'), S.ratePositive);
    expect(validateRate('0.001'), isNull);
    expect(validateRate('7.125'), isNull);
    expect(tryParseRateMilli('7.125'), 7125);
    expect(validateRate('7.1255'), S.rateFormat);
    expect(validateRate('20'), isNull);
    expect(validateRate('20.001'), S.rateTooHigh);
    expect(validateRate('-1'), S.rateFormat);
  });

  test('tenure boxes: whole numbers, not all blank', () {
    expect(validateTenureFields('', '', ''), S.enterTenure);
    expect(validateTenureFields('1', '', ''), isNull);
    expect(validateTenureFields('', '', '90'), isNull);
    expect(validateTenureFields('1.5', '', ''), S.tenureWhole);
    expect(tryParseTenure('1', '', '7'), const Tenure(1, 0, 7));
  });

  test('maturity after start; tenure at most 10 years; future start ok', () {
    expect(
      validateFdDates(d('2026-10-21'), d('2026-10-21')),
      S.maturityAfterStart,
    );
    expect(
      validateFdDates(d('2026-10-21'), d('2026-10-20')),
      S.maturityAfterStart,
    );
    expect(validateFdDates(d('2026-10-21'), d('2036-10-21')), isNull);
    expect(validateFdDates(d('2026-10-21'), d('2036-10-22')), S.tenureTooLong);
    expect(validateFdDates(d('2030-01-01'), d('2031-01-01')), isNull);
  });

  test('receipt amount must exceed the principal', () {
    expect(validateReceiptAmount('', 10000000), isNull);
    expect(validateReceiptAmount('100000', 10000000), S.receiptAboveFrom);
    expect(validateReceiptAmount('99999', 10000000), S.receiptAboveFrom);
    expect(validateReceiptAmount('107185.90', 10000000), isNull);
    expect(validateReceiptAmount('abc', 10000000), S.amountFormat);
  });

  test('optional amounts (payout per period)', () {
    expect(validateOptionalAmount(''), isNull);
    expect(validateOptionalAmount('0'), S.amountPositive);
    expect(validateOptionalAmount('583.33'), isNull);
  });

  test('notes: at most 200 characters', () {
    expect(validateNotes('a' * 200), isNull);
    expect(validateNotes('a' * 201), S.notesTooLong);
    expect(cleanNotes('  '), isNull);
    expect(cleanNotes(' hi '), 'hi');
  });
}
