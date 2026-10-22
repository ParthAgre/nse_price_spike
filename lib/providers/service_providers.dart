import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:nse_price_spike/models/app_settings.dart';
import 'package:nse_price_spike/services/file_cache.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';
import 'package:nse_price_spike/services/network_log.dart';
import 'package:nse_price_spike/services/nse_bhavcopy_provider.dart';
import 'package:nse_price_spike/services/price_provider.dart';

/// Overridden in tests to pin "now".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Parse files on a background isolate. Tests turn this off.
final useIsolateProvider = Provider<bool>((ref) => true);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final networkLogProvider = ChangeNotifierProvider<NetworkLog>(
  (ref) => NetworkLog(),
);

final fixtureLoaderProvider = Provider<FixtureLoader>(
  (ref) => loadFixtureAsset,
);

final fileCacheProvider = Provider<FileCache>((ref) => DirectoryFileCache());

/// Builds the [PriceProvider] for a mode.
final priceProviderFactoryProvider =
    Provider<PriceProvider Function(PriceMode)>((ref) {
      final log = ref.read(networkLogProvider);
      final clock = ref.read(clockProvider);
      final useIsolate = ref.read(useIsolateProvider);
      return (mode) => switch (mode) {
        PriceMode.fixture => FixturePriceProvider(
          load: ref.read(fixtureLoaderProvider),
          log: log,
          useIsolate: useIsolate,
          clock: clock,
        ),
        PriceMode.live => NseBhavcopyProvider(
          client: ref.read(httpClientProvider),
          log: log,
          useIsolate: useIsolate,
          clock: clock,
        ),
      };
    });
