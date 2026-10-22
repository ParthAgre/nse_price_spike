import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/services/equity_list_parser.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';
import 'package:nse_price_spike/utils/symbol_search.dart';

import '../helpers/fixtures.dart';

void main() {
  late SymbolSearchIndex index;

  setUpAll(() {
    // Same composition as symbol_master: EQUITY_L stocks + bhavcopy ETFs.
    final stocks = parseEquityList(fixtureText(fixtureEquityListFile)).entries;
    final etfs = fixtureDailyFile().rows
        .where((r) => r.type == InstrumentType.etf)
        .map(
          (r) => SymbolEntry(
            isin: r.isin,
            symbol: r.symbol,
            name: r.name,
            type: r.type,
            series: r.series,
          ),
        );
    index = SymbolSearchIndex([...stocks, ...etfs]);
  });

  test('"reli" finds RELIANCE among the symbol-prefix matches', () {
    final results = index.search('reli');
    final symbols = results.map((e) => e.symbol).toList();
    expect(symbols, contains('RELIANCE'));
    // Prefix matches rank shortest-first then A–Z, so RELIABLE precedes it;
    // there is no popularity data to rank by.
    final prefixCount = symbols.where((s) => s.startsWith('RELI')).length;
    expect(symbols.indexOf('RELIANCE'), lessThan(prefixCount));
    expect(
      results.firstWhere((e) => e.symbol == 'RELIANCE').isin,
      'INE002A01018',
    );
  });

  test('exact ISIN match ranks first', () {
    final results = index.search('ine002a01018');
    expect(results.first.symbol, 'RELIANCE');
  });

  test('NIFTYBEES ETF is found', () {
    final results = index.search('niftybees');
    expect(results.first.symbol, 'NIFTYBEES');
    expect(results.first.type, InstrumentType.etf);
    expect(results.first.isin, 'INF204KB14I2');
  });

  test('matches on name too', () {
    final results = index.search('reliance industries');
    expect(results.map((e) => e.symbol), contains('RELIANCE'));
  });

  test('symbol-prefix matches come before name-only matches', () {
    final results = index.search('tata');
    final firstNameOnly = results.indexWhere(
      (e) => !e.symbol.toLowerCase().contains('tata'),
    );
    final lastPrefix = results.lastIndexWhere(
      (e) => e.symbol.toLowerCase().startsWith('tata'),
    );
    if (firstNameOnly != -1) expect(lastPrefix, lessThan(firstNameOnly));
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
    // ~2,900 entries; 7 searches well under a frame budget on a desktop VM.
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
    expect(index.length, greaterThan(2900));
  });
}
