import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/models/app_settings.dart';
import 'package:nse_price_spike/providers/refresh_providers.dart';
import 'package:nse_price_spike/providers/repository_providers.dart';
import 'package:nse_price_spike/providers/service_providers.dart';
import 'package:nse_price_spike/services/bhavcopy_parser.dart';
import 'package:nse_price_spike/services/refresh_service.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  Future<void> _downloadNow(BuildContext context, WidgetRef ref) async {
    final outcome = await ref
        .read(refreshControllerProvider.notifier)
        .refresh(force: true);
    if (!context.mounted) return;
    showSnack(
      context,
      outcome is RefreshFailed
          ? '${outcome.message}\n${outcome.detail}'
          : outcome.message,
    );
  }

  Future<void> _redownloadEquityList(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final outcome = await ref
        .read(refreshControllerProvider.notifier)
        .redownloadEquityList();
    if (!context.mounted) return;
    showSnack(context, switch (outcome) {
      EquityListUpdated(:final stocks) => 'EQUITY_L: $stocks stocks loaded',
      EquityListFailed(:final error) => 'EQUITY_L failed: $error',
      EquityListSkipped() => 'EQUITY_L is up to date',
    });
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Clear cache?',
      message:
          'Deletes downloaded NSE prices and the cached file. Holdings, '
          'manual prices and the symbol list are kept. The next refresh '
          'downloads again.',
      confirmLabel: 'Clear',
    );
    if (!ok) return;
    await ref.read(refreshControllerProvider.notifier).clearCache();
    if (context.mounted) showSnack(context, 'Cache cleared');
  }

  Future<void> _resetDatabase(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reset database?',
      message:
          'Deletes ALL holdings, entries, prices, the symbol list and '
          'settings. The app goes back to Fixture mode. This cannot be undone.',
      confirmLabel: 'Reset',
    );
    if (!ok) return;
    await ref.read(refreshControllerProvider.notifier).resetDatabase();
    if (context.mounted) showSnack(context, 'Database reset');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettingsView({});
    final busy = ref.watch(refreshControllerProvider.select((s) => s.busy));
    final symbolCount = ref
        .watch(symbolSearchIndexProvider)
        .valueOrNull
        ?.length;
    final events = ref.watch(networkLogProvider).events;
    final theme = Theme.of(context);

    String orDash(Object? v) => v == null ? '—' : '$v';
    final fetchedAt = settings.lastFileFetchedAt;
    final equityAt = settings.equityListFetchedAt;
    final size = settings.lastFileSize;

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 4,
            child: busy ? const LinearProgressIndicator() : null,
          ),
          SwitchListTile(
            title: const Text('Live mode (NSE)'),
            subtitle: Text(
              settings.mode == PriceMode.live
                  ? 'Downloads from nsearchives.nseindia.com'
                  : 'Fixture mode: bundled 21 Oct 2026 files, no network',
            ),
            value: settings.mode == PriceMode.live,
            onChanged: (live) => ref
                .read(refreshControllerProvider.notifier)
                .setMode(live ? PriceMode.live : PriceMode.fixture),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                StatRow(
                  'Last file date',
                  Text(
                    settings.lastFileTradeDate == null
                        ? '—'
                        : formatDisplayDate(settings.lastFileTradeDate!),
                  ),
                ),
                StatRow(
                  'Downloaded at (IST)',
                  Text(fetchedAt == null ? '—' : formatIstTime(fetchedAt)),
                ),
                StatRow(
                  'File size',
                  Text(size == null ? '—' : formatBytes(size)),
                ),
                StatRow('Rows parsed', Text(orDash(settings.lastRowsParsed))),
                StatRow(
                  'Holdings matched',
                  Text(orDash(settings.lastHoldingsMatched)),
                ),
                StatRow('symbol_master size', Text(orDash(symbolCount))),
                StatRow(
                  'EQUITY_L fetched (IST)',
                  Text(
                    equityAt == null
                        ? '—'
                        : '${formatIstTime(equityAt)} · '
                              '${orDash(settings.equityListRows)} rows',
                  ),
                ),
                StatRow(
                  'Last refresh',
                  Text(orDash(settings.lastRefreshMessage)),
                ),
                if (settings.lastRefreshError != null)
                  StatRow(
                    'Last error',
                    Text(
                      settings.lastRefreshError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Rows per series (kept: ${keptSeries.join(', ')})',
              style: theme.textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: settings.lastSeriesCounts.isEmpty
                ? const Text('No file parsed yet.')
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final MapEntry(key: series, value: count)
                          in settings.lastSeriesCounts)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '${series.isEmpty ? '(blank)' : series} $count',
                            style: keptSeries.contains(series)
                                ? const TextStyle(fontWeight: FontWeight.bold)
                                : null,
                          ),
                        ),
                    ],
                  ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: busy ? null : () => _downloadNow(context, ref),
                  child: const Text('Download now'),
                ),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _redownloadEquityList(context, ref),
                  child: const Text('Re-download EQUITY_L'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => _clearCache(context, ref),
                  child: const Text('Clear cache'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: busy ? null : () => _resetDatabase(context, ref),
                  child: const Text('Reset database'),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Last ${events.length} network events (this session)',
              style: theme.textTheme.titleSmall,
            ),
          ),
          for (final e in events)
            ListTile(
              dense: true,
              title: Text(e.url, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${formatIstTime(e.time)} · ${e.status} · '
                '${e.duration.inMilliseconds} ms'
                '${e.bytes == null ? '' : ' · ${formatBytes(e.bytes!)}'}',
              ),
            ),
        ],
      ),
    );
  }
}
