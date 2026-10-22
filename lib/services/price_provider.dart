import 'dart:convert';
import 'dart:isolate';

import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/services/equity_list_parser.dart';

/// A source of end-of-day prices. Implementations throw only
/// [PriceFetchException] subtypes.
abstract interface class PriceProvider {
  /// Short name for logs and the Debug screen.
  String get label;

  /// The parsed bhavcopy for [tradingDay]. Throws [PriceNotFound] when no
  /// file exists for that day (holiday / not yet published).
  Future<DailyFile> fetchForDate(DateTime tradingDay);

  /// The parsed EQUITY_L.csv symbol list.
  Future<EquityList> fetchEquityList();
}

/// Runs a CPU-heavy parse of [input] off the UI isolate, or inline when
/// [useIsolate] is false (tests, where a real isolate would escape the fake
/// clock). [parse] must be a top-level function so the closure sent to the
/// isolate captures nothing else.
Future<T> runParse<A, T>(
  T Function(A input) parse,
  A input, {
  required bool useIsolate,
}) => useIsolate
    ? Isolate.run(() => parse(input))
    : Future.sync(() => parse(input));

/// [parseEquityList] over raw bytes, for [runParse].
EquityList parseEquityListBytes(List<int> bytes) =>
    parseEquityList(utf8.decode(bytes, allowMalformed: true));
