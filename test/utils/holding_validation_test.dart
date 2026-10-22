import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/utils/holding_validation.dart';

void main() {
  test('quantity must be > 0', () {
    expect(validateQuantity('', InstrumentType.stock), isNotNull);
    expect(validateQuantity('0', InstrumentType.stock), isNotNull);
    expect(validateQuantity('abc', InstrumentType.stock), isNotNull);
    expect(validateQuantity('10', InstrumentType.stock), isNull);
  });

  test('stocks need whole numbers; ETFs allow up to 4 decimals', () {
    expect(validateQuantity('1.5', InstrumentType.stock), isNotNull);
    expect(validateQuantity('1.5', InstrumentType.etf), isNull);
    expect(validateQuantity('1.00001', InstrumentType.etf), isNotNull);
  });

  test('price must be > 0 with at most 2 decimals', () {
    expect(validatePrice(''), isNotNull);
    expect(validatePrice('0'), isNotNull);
    expect(validatePrice('0.00'), isNotNull);
    expect(validatePrice('12.345'), isNotNull);
    expect(validatePrice('1209.50'), isNull);
  });

  test('fees are optional', () {
    expect(validateFees(''), isNull);
    expect(validateFees('20.5'), isNull);
    expect(validateFees('-1'), isNotNull);
  });
}
