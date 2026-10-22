import 'package:flutter/services.dart';
import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/models/network_event.dart';
import 'package:nse_price_spike/services/bhavcopy_parser.dart';
import 'package:nse_price_spike/services/equity_list_parser.dart';
import 'package:nse_price_spike/services/network_log.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';
import 'package:nse_price_spike/services/price_provider.dart';

/// Loads a fixture file's bytes by file name.
typedef FixtureLoader = Future<Uint8List> Function(String fileName);

/// Fixture files bundled as assets (see `flutter: assets:` in pubspec.yaml).
const fixtureAssetDir = 'test/fixtures';
const fixtureBhavcopyFile = 'bhav_20261021.zip';
const fixtureEquityListFile = 'EQUITY_L.csv';

Future<Uint8List> loadFixtureAsset(String fileName) async {
  final data = await rootBundle.load('$fixtureAssetDir/$fileName');
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// Offline provider: serves the bundled 21 Oct 2026 bhavcopy for any
/// requested day (the stored trade date comes from the file's TradDt).
class FixturePriceProvider implements PriceProvider {
  final FixtureLoader load;
  final NetworkLog? log;
  final bool useIsolate;
  final DateTime Function() clock;

  FixturePriceProvider({
    this.load = loadFixtureAsset,
    this.log,
    this.useIsolate = true,
    this.clock = DateTime.now,
  });

  @override
  String get label => 'Fixture';

  Future<Uint8List> _load(String fileName) async {
    final started = clock();
    final stopwatch = Stopwatch()..start();
    try {
      final bytes = await load(fileName);
      log?.add(
        NetworkEvent(
          time: started,
          url: 'fixture://$fileName',
          status: 'fixture',
          duration: stopwatch.elapsed,
          bytes: bytes.length,
        ),
      );
      return bytes;
    } on Object catch (e) {
      log?.add(
        NetworkEvent(
          time: started,
          url: 'fixture://$fileName',
          status: 'error',
          duration: stopwatch.elapsed,
        ),
      );
      throw PriceNetworkFailure('fixture $fileName unavailable: $e');
    }
  }

  @override
  Future<DailyFile> fetchForDate(DateTime tradingDay) async {
    final bytes = await _load(fixtureBhavcopyFile);
    return runParse(parseBhavcopyZip, bytes, useIsolate: useIsolate);
  }

  @override
  Future<EquityList> fetchEquityList() async {
    final bytes = await _load(fixtureEquityListFile);
    return runParse(parseEquityListBytes, bytes, useIsolate: useIsolate);
  }
}
