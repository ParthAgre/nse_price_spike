import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/utils/instrument_type.dart';

void main() {
  test('INE with type code 01 is a stock', () {
    expect(instrumentTypeFromIsin('INE002A01018'), InstrumentType.stock);
    expect(instrumentTypeFromIsin(' ine0o6n01012 '), InstrumentType.stock);
  });

  test('INF is an ETF', () {
    expect(instrumentTypeFromIsin('INF204KB14I2'), InstrumentType.etf);
  });

  test('other INE type codes are ignored', () {
    expect(instrumentTypeFromIsin('INE916Y07073'), isNull); // debenture
    expect(instrumentTypeFromIsin('INE2OVN25015'), isNull); // REIT
    expect(instrumentTypeFromIsin('INE1UA823019'), isNull); // InvIT
    expect(instrumentTypeFromIsin('INE0LXG20016'), isNull); // rights
    expect(instrumentTypeFromIsin('INE804IA7014'), isNull); // NCD "A7"
  });

  test('other prefixes and malformed ISINs are ignored', () {
    expect(instrumentTypeFromIsin('IN0020200104'), isNull); // gold bond
    expect(instrumentTypeFromIsin('IN9175A01010'), isNull); // DVR
    expect(instrumentTypeFromIsin('INE002A0101'), isNull); // 11 chars
    expect(instrumentTypeFromIsin(''), isNull);
  });
}
