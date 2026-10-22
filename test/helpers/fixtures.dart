import 'dart:io';
import 'dart:typed_data';

import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/services/bhavcopy_parser.dart';
import 'package:nse_price_spike/services/equity_list_parser.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';
import 'package:nse_price_spike/services/price_provider.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

const bhavCsvFile = 'BhavCopy_NSE_CM_0_0_0_20261021_F_0000.csv';

Uint8List fixtureBytes(String name) =>
    File('test/fixtures/$name').readAsBytesSync();

String fixtureText(String name) =>
    File('test/fixtures/$name').readAsStringSync();

/// Reads fixture files synchronously up front, so the loader works inside
/// widget tests' fake async zone.
FixtureLoader memoryFixtureLoader() {
  final files = {
    fixtureBhavcopyFile: fixtureBytes(fixtureBhavcopyFile),
    fixtureEquityListFile: fixtureBytes(fixtureEquityListFile),
  };
  return (name) async => files[name]!;
}

DailyFile? _fixtureFile;

/// The real 21 Oct 2026 bhavcopy, parsed once.
DailyFile fixtureDailyFile() =>
    _fixtureFile ??= parseBhavcopyZip(fixtureBytes(fixtureBhavcopyFile));

/// The fixture's rows re-dated to [day], to simulate other trading days.
DailyFile dailyFileFor(DateTime day, {Map<String, BhavRow>? rows}) {
  final base = fixtureDailyFile();
  return DailyFile(
    tradeDate: dateOnly(day),
    rowsByIsin: rows ?? base.rowsByIsin,
    seriesCounts: base.seriesCounts,
    rowsParsed: base.rowsParsed,
    rowsSkipped: base.rowsSkipped,
    sizeBytes: base.sizeBytes,
    rawZip: base.rawZip,
  );
}

/// A [PriceProvider] whose answer per day is scripted: a [DailyFile], or an
/// exception to throw. Unscripted days are 404s. Records requested days.
class ScriptedPriceProvider implements PriceProvider {
  final Map<DateTime, Object> byDay;
  final List<DateTime> requested = [];
  int equityListCalls = 0;
  Object? equityListError;

  ScriptedPriceProvider([Map<DateTime, Object>? byDay]) : byDay = byDay ?? {};

  @override
  String get label => 'Scripted';

  @override
  Future<DailyFile> fetchForDate(DateTime tradingDay) async {
    requested.add(tradingDay);
    final answer = byDay[dateOnly(tradingDay)];
    if (answer == null) {
      throw PriceNotFound('scripted://${dateKey(tradingDay)}');
    }
    if (answer is DailyFile) return answer;
    throw answer;
  }

  @override
  Future<EquityList> fetchEquityList() async {
    equityListCalls++;
    if (equityListError != null) throw equityListError!;
    return parseEquityList(fixtureText(fixtureEquityListFile));
  }
}

/// `YYYY-MM-DD` → date-only UTC, for readable test tables.
DateTime d(String key) => parseDateKey(key)!;

/// An instant at the given IST wall-clock time.
DateTime ist(int y, int m, int day, int hour, [int minute = 0]) =>
    DateTime.utc(y, m, day, hour, minute).subtract(istOffset);
