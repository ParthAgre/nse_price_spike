import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nse_price_spike/constants/nse_urls.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';
import 'package:nse_price_spike/services/network_log.dart';
import 'package:nse_price_spike/services/nse_bhavcopy_provider.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';

import '../helpers/fixtures.dart';

/// No test here touches the real network: every request goes to MockClient.
NseBhavcopyProvider providerFor(
  Future<http.Response> Function(http.Request) handler, {
  NetworkLog? log,
  Duration timeout = const Duration(seconds: 5),
}) => NseBhavcopyProvider(
  client: MockClient(handler),
  log: log,
  timeout: timeout,
  useIsolate: false,
);

http.Response bytesResponse(List<int> body, [int status = 200]) =>
    http.Response.bytes(body, status);

void main() {
  final day = d('2026-10-21');

  test('URL comes from the single pattern constant', () {
    expect(
      bhavcopyUrlFor(day),
      'https://nsearchives.nseindia.com/content/cm/'
      'BhavCopy_NSE_CM_0_0_0_20261021_F_0000.csv.zip',
    );
    expect(bhavcopyUrlPattern, contains('{YYYYMMDD}'));
  });

  test('sends a browser User-Agent and parses the zip', () async {
    late http.Request seen;
    final log = NetworkLog();
    final provider = providerFor((req) async {
      seen = req;
      return bytesResponse(fixtureBytes(fixtureBhavcopyFile));
    }, log: log);

    final file = await provider.fetchForDate(day);

    expect(seen.url.toString(), bhavcopyUrlFor(day));
    expect(seen.headers['User-Agent'], contains('Mozilla/5.0'));
    expect(file.rowsByIsin['INE002A01018']!.closePaise, 120900);
    expect(log.events.single.status, '200');
    expect(log.events.single.url, bhavcopyUrlFor(day));
  });

  test('404 → PriceNotFound', () async {
    final provider = providerFor((_) async => http.Response('Not Found', 404));
    await expectLater(
      provider.fetchForDate(day),
      throwsA(isA<PriceNotFound>()),
    );
  });

  test('403 → PriceForbidden', () async {
    final provider = providerFor(
      (_) async => http.Response('<html>Denied</html>', 403),
    );
    await expectLater(
      provider.fetchForDate(day),
      throwsA(isA<PriceForbidden>()),
    );
  });

  test('500 → PriceHttpFailure', () async {
    final provider = providerFor((_) async => http.Response('oops', 500));
    await expectLater(
      provider.fetchForDate(day),
      throwsA(
        isA<PriceHttpFailure>().having((e) => e.statusCode, 'status', 500),
      ),
    );
  });

  test(
    '200 with a plain-text body (eod_reliance.json) → PriceNotAZip',
    () async {
      final provider = providerFor(
        (_) async => bytesResponse(fixtureBytes('eod_reliance.json')),
      );
      await expectLater(
        provider.fetchForDate(day),
        throwsA(isA<PriceNotAZip>()),
      );
    },
  );

  test(
    '200 with another plain-text body (nse_symbols.json) → PriceNotAZip',
    () async {
      final provider = providerFor(
        (_) async => bytesResponse(fixtureBytes('nse_symbols.json')),
      );
      await expectLater(
        provider.fetchForDate(day),
        throwsA(
          isA<PriceNotAZip>().having(
            (e) => e.bodyPreview,
            'preview',
            'Exchange Not Found.',
          ),
        ),
      );
    },
  );

  test('200 with an HTML body → PriceNotAZip', () async {
    final provider = providerFor(
      (_) async =>
          bytesResponse(utf8.encode('<!DOCTYPE html><html>Error</html>')),
    );
    await expectLater(provider.fetchForDate(day), throwsA(isA<PriceNotAZip>()));
  });

  test('200 with an empty zip → PriceParseFailure', () async {
    final provider = providerFor(
      (_) async => bytesResponse(
        Uint8List.fromList([0x50, 0x4B, 0x05, 0x06, ...List.filled(18, 0)]),
      ),
    );
    await expectLater(
      provider.fetchForDate(day),
      throwsA(isA<PriceParseFailure>()),
    );
  });

  test('slow response → PriceTimeout, logged', () async {
    final log = NetworkLog();
    final never = Completer<http.Response>();
    final provider = providerFor(
      (_) => never.future,
      log: log,
      timeout: const Duration(milliseconds: 20),
    );
    await expectLater(provider.fetchForDate(day), throwsA(isA<PriceTimeout>()));
    expect(log.events.single.status, 'timeout');
  });

  test('connection error → PriceNetworkFailure', () async {
    final provider = providerFor(
      (_) async => throw http.ClientException('no route'),
    );
    await expectLater(
      provider.fetchForDate(day),
      throwsA(isA<PriceNetworkFailure>()),
    );
  });

  test('EQUITY_L.csv download is parsed', () async {
    late Uri seen;
    final provider = providerFor((req) async {
      seen = req.url;
      return bytesResponse(fixtureBytes(fixtureEquityListFile));
    });
    final list = await provider.fetchEquityList();
    expect(seen.toString(), equityListUrl);
    expect(list.entries.any((e) => e.symbol == '20MICRONS'), isTrue);
  });

  test('network log keeps the last 20 events', () async {
    final log = NetworkLog();
    final provider = providerFor((_) async => http.Response('', 404), log: log);
    for (var i = 0; i < 25; i++) {
      await expectLater(
        provider.fetchForDate(day),
        throwsA(isA<PriceNotFound>()),
      );
    }
    expect(log.events.length, NetworkLog.capacity);
  });
}
