import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/services/equity_list_parser.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';
import 'package:nse_price_spike/utils/symbol_search.dart';

import '../helpers/fixtures.dart';

SymbolEntry entry(String symbol, {String? name, String? isin}) => SymbolEntry(
  isin: isin ?? 'INE${symbol.padRight(6, '0').substring(0, 6)}01011',
  symbol: symbol,
  name: name ?? '$symbol Limited',
  type: InstrumentType.stock,
);

void main() {
  late SymbolSearchIndex index;

  setUpAll(() {
    // Same composition as symbol_master: EQUITY_L stocks, plus bhavcopy rows
    // EQUITY_L lacks (ETFs, SM/ST stocks), ranked by the file's TtlTrfVal.
    final stocks = parseEquityList(fixtureText(fixtureEquityListFile)).entries;
    final known = {for (final s in stocks) s.isin};
    final file = fixtureDailyFile();
    final fromFile = file.rows
        .where((r) => !known.contains(r.isin))
        .map(
          (r) => SymbolEntry(
            isin: r.isin,
            symbol: r.symbol,
            name: r.name,
            type: r.type,
            series: r.series,
          ),
        );
    index = SymbolSearchIndex(
      [...stocks, ...fromFile],
      tradedValueByIsin: {
        for (final r in file.rows)
          if (r.tradedValuePaise != null) r.isin: r.tradedValuePaise!,
      },
    );
  });

  test('"reli" ranks RELIANCE above RELIABLE (by traded value)', () {
    final symbols = index.search('reli').map((e) => e.symbol).toList();
    expect(symbols.first, 'RELIANCE');
    expect(symbols.indexOf('RELIANCE'), lessThan(symbols.indexOf('RELIABLE')));
  });

  test('an exact "TCS" comes first', () {
    final results = index.search('TCS');
    expect(results.first.symbol, 'TCS');
    expect(results.first.isin, 'INE467B01029');
  });

  test('exact ISIN match ranks first', () {
    expect(index.search('ine002a01018').first.symbol, 'RELIANCE');
  });

  test('NIFTYBEES ETF is found', () {
    final results = index.search('niftybees');
    expect(results.first.symbol, 'NIFTYBEES');
    expect(results.first.type, InstrumentType.etf);
    expect(results.first.isin, 'INF204KB14I2');
  });

  test('SME (SM) stocks from the bhavcopy are searchable', () {
    expect(index.search('agul').first.isin, 'INE0O6N01012');
  });

  test('matches on name too', () {
    final results = index.search('reliance industries');
    expect(results.map((e) => e.symbol), contains('RELIANCE'));
  });

  group('ranking rules (synthetic)', () {
    final idx = SymbolSearchIndex(
      [
        entry('ABCX', name: 'Zed Abc Holdings'),
        entry('ABCD'),
        entry('ABC'),
        entry('ABCZ'),
        entry('XYZ', name: 'Abc Works'),
        entry('NOVAL', name: 'Abc No Value'),
      ],
      tradedValueByIsin: {
        entry('ABCD').isin: 100,
        entry('ABCZ').isin: 900,
        entry('XYZ').isin: 50,
      },
    );

    test('exact symbol → prefix → name contains', () {
      expect(idx.search('abc').map((e) => e.symbol), [
        'ABC', // exact
        'ABCZ', 'ABCD', 'ABCX', // prefix: 900, 100, no value
        'XYZ', 'NOVAL', // name contains: 50, no value
      ]);
    });

    test('no traded value: after valued ones, then A–Z', () {
      final idx2 = SymbolSearchIndex(
        [entry('ABQ'), entry('ABP'), entry('ABR')],
        tradedValueByIsin: {entry('ABR').isin: 1},
      );
      expect(idx2.search('ab').map((e) => e.symbol), ['ABR', 'ABP', 'ABQ']);
    });

    test('symbol "contains" alone is not a match', () {
      // "BCD" is inside XBCDY but neither a prefix nor in the name.
      final idx3 = SymbolSearchIndex([entry('XBCDY', name: 'Other Co')]);
      expect(idx3.search('bcd'), isEmpty);
    });
  });

  test('caps at 30 results; empty query gives none', () {
    expect(index.search('a').length, maxSearchResults);
    expect(index.search('   '), isEmpty);
  });

  test('is fast enough for per-keystroke use', () {
    final stopwatch = Stopwatch()..start();
    for (final q in ['r', 're', 'rel', 'reli', 'relia', 'nifty', 'bank']) {
      index.search(q);
    }
    stopwatch.stop();
    // ~3,400 entries; 7 searches well under a frame budget on a desktop VM.
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
    expect(index.length, 3434);
  });
}
