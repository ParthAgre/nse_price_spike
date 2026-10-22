import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nse_price_spike/constants/nse_urls.dart';
import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/models/network_event.dart';
import 'package:nse_price_spike/services/bhavcopy_parser.dart';
import 'package:nse_price_spike/services/equity_list_parser.dart';
import 'package:nse_price_spike/services/network_log.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';
import 'package:nse_price_spike/services/price_provider.dart';

/// Live provider: downloads from nsearchives.nseindia.com.
class NseBhavcopyProvider implements PriceProvider {
  final http.Client client;
  final NetworkLog? log;
  final Duration timeout;
  final bool useIsolate;
  final DateTime Function() clock;

  NseBhavcopyProvider({
    required this.client,
    this.log,
    this.timeout = const Duration(seconds: 20),
    this.useIsolate = true,
    this.clock = DateTime.now,
  });

  @override
  String get label => 'NSE (live)';

  static const _headers = {
    'User-Agent': browserUserAgent,
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  Future<Uint8List> _get(String url) async {
    final started = clock();
    final stopwatch = Stopwatch()..start();
    void record(String status, [int? bytes]) => log?.add(
      NetworkEvent(
        time: started,
        url: url,
        status: status,
        duration: stopwatch.elapsed,
        bytes: bytes,
      ),
    );

    final http.Response response;
    try {
      response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(timeout);
    } on TimeoutException {
      record('timeout');
      throw PriceTimeout(url);
    } on Exception catch (e) {
      record('error');
      throw PriceNetworkFailure(e.toString());
    }

    record('${response.statusCode}', response.bodyBytes.length);
    switch (response.statusCode) {
      case 200:
        return response.bodyBytes;
      case 404:
        throw PriceNotFound(url);
      case 403:
        throw PriceForbidden(url);
      default:
        throw PriceHttpFailure(response.statusCode, url);
    }
  }

  @override
  Future<DailyFile> fetchForDate(DateTime tradingDay) async {
    final bytes = await _get(bhavcopyUrlFor(tradingDay));
    if (!looksLikeZip(bytes)) throw PriceNotAZip(bodyPreview(bytes));
    try {
      return await runParse(parseBhavcopyZip, bytes, useIsolate: useIsolate);
    } on PriceFetchException {
      rethrow;
    } on Object catch (e) {
      throw PriceParseFailure(e.toString());
    }
  }

  @override
  Future<EquityList> fetchEquityList() async {
    final bytes = await _get(equityListUrl);
    try {
      return await runParse(
        parseEquityListBytes,
        bytes,
        useIsolate: useIsolate,
      );
    } on PriceFetchException {
      rethrow;
    } on Object catch (e) {
      throw PriceParseFailure(e.toString());
    }
  }
}
