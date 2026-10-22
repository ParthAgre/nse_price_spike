import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/services/csv_table.dart';
import 'package:nse_price_spike/services/equity_list_parser.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';

import '../helpers/fixtures.dart';

void main() {
  final text = fixtureText(fixtureEquityListFile);

  test('the real file has leading spaces in headers, which are trimmed', () {
    expect(text.split('\n').first, contains(' SERIES'));
    expect(text.split('\n').first, contains(' ISIN NUMBER'));
    final table = CsvTable.parse(text);
    expect(
      table.headers,
      containsAll(['SYMBOL', 'NAME OF COMPANY', 'SERIES', 'ISIN NUMBER']),
    );
  });

  test('20MICRONS is present with ISIN INE144J01027', () {
    final list = parseEquityList(text);
    final micron = list.entries.firstWhere((e) => e.symbol == '20MICRONS');
    expect(micron.isin, 'INE144J01027');
    expect(micron.name, '20 Microns Limited');
    expect(micron.series, 'EQ');
    expect(micron.type, InstrumentType.stock);
  });

  test('a rights entitlement (INE, type code 20) is ignored', () {
    final list = parseEquityList(text);
    expect(text, contains('INE0LXG20016')); // OLAELEC-RE
    expect(list.entries.any((e) => e.isin == 'INE0LXG20016'), isFalse);
  });

  test('keeps INE…01 rows, ignores other ISIN prefixes and codes', () {
    final list = parseEquityList(text);
    expect(list.rowsParsed, 2608);
    expect(list.entries.every((e) => e.isin.startsWith('INE')), isTrue);
    expect(
      list.entries.length,
      2605,
      reason: "two IN9 rows and the OLAELEC-RE rights entitlement are ignored",
    );
  });

  test('HTML instead of CSV is a parse failure', () {
    expect(
      () => parseEquityList('<html><body>Access Denied</body></html>'),
      throwsA(isA<PriceParseFailure>()),
    );
  });
}
