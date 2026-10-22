import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/providers/refresh_providers.dart';
import 'package:nse_price_spike/providers/repository_providers.dart';
import 'package:nse_price_spike/screens/debug_screen.dart';
import 'package:nse_price_spike/screens/holding_detail_screen.dart';
import 'package:nse_price_spike/screens/search_screen.dart';
import 'package:nse_price_spike/services/refresh_service.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/portfolio_math.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final outcome = await ref
        .read(refreshControllerProvider.notifier)
        .refresh();
    if (context.mounted && outcome is! RefreshFailed) {
      showSnack(context, outcome.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(refreshControllerProvider.select((s) => s.busy));
    final settings = ref.watch(settingsProvider).valueOrNull;
    final holdings = ref.watch(holdingsProvider);
    final totals = ref.watch(portfolioTotalsProvider);
    final fileDate = settings?.lastFileTradeDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            key: const Key('refreshButton'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: busy ? null : () => _refresh(context, ref),
          ),
          IconButton(
            tooltip: 'Debug',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DebugScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addButton'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            SizedBox(
              height: 4,
              child: busy ? const LinearProgressIndicator() : null,
            ),
            if (settings?.lastRefreshError != null)
              MaterialBanner(
                content: Text("Couldn't reach NSE — ${pricesAsOf(fileDate)}"),
                leading: const Icon(Icons.cloud_off),
                actions: [
                  TextButton(
                    onPressed: busy ? null : () => _refresh(context, ref),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            _SummaryCard(
              totals: totals.valueOrNull ?? PortfolioTotals.empty,
              fileDate: fileDate,
            ),
            ...holdings.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Could not load holdings: $e'),
                ),
              ],
              data: (list) => list.isEmpty
                  ? const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No holdings yet. Tap "Add" to add a stock or ETF.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ]
                  : [for (final h in list) _HoldingTile(h)],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PortfolioTotals totals;
  final DateTime? fileDate;

  const _SummaryCard({required this.totals, required this.fileDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total value', style: theme.textTheme.labelLarge),
            Text(
              formatRupees(totals.valuePaise),
              key: const Key('totalValue'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            StatRow('Invested', Text(formatRupees(totals.investedPaise))),
            StatRow(
              'Unrealised P&L',
              PnlText(totals.pnlPaise, fraction: totals.pnlFraction),
            ),
            StatRow(
              "Today's change",
              PnlText(
                totals.dayChangePaise,
                key: const Key('dayChange'),
                fraction: totals.dayChangeFraction,
              ),
            ),
            if (totals.unpricedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${totals.unpricedCount} holding(s) have no price yet and '
                  'are not in the value.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              fileDate == null
                  ? 'No NSE prices yet · NSE closing prices'
                  : 'Prices as of ${formatDisplayDate(fileDate!)} · '
                        'NSE closing prices',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  final Holding holding;

  const _HoldingTile(this.holding);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = holding;
    final avg = h.averageCostPaise;
    final price = h.price;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HoldingDetailScreen(instrumentId: h.instrument.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.instrument.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${h.instrument.symbol} · ${h.instrument.type.label}',
                        style: muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      h.valuePaise == null ? '—' : formatRupees(h.valuePaise!),
                      style: theme.textTheme.titleSmall,
                    ),
                    PnlText(
                      h.pnlPaise,
                      fraction: h.pnlPaise == null
                          ? null
                          : fractionOf(h.pnlPaise!, h.investedPaise),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Qty ${formatQuantity(h.quantityScaled)} · '
              'Avg ${avg == null ? '—' : formatRupees(avg)} · '
              'Close ${price == null ? '—' : formatRupees(price.closePaise)}'
              '${price?.source == QuoteSource.manual ? ' (manual)' : ''}',
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}
