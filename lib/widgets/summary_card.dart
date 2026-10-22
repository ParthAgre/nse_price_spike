import 'package:flutter/material.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/widgets/allocation_bar.dart';
import 'package:nse_price_spike/widgets/common.dart';

/// Current value, invested, returns and today's change, plus the
/// allocation bar when more than one asset class is held.
class SummaryCard extends StatelessWidget {
  final InvestmentsSummary summary;

  /// "21 Oct 2026", or null before the first NSE file.
  final String? marketDate;
  final VoidCallback onInfo;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.marketDate,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final allocation = summary.allocation;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.currentValue, style: theme.textTheme.labelLarge),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatRupeesWhole(summary.currentValuePaise),
                key: const Key('totalValue'),
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            StatRow(
              S.invested,
              Text(
                formatRupees(summary.investedPaise),
                key: const Key('investedTotal'),
              ),
            ),
            StatRow(
              S.returns,
              labelTrailing: IconButton(
                key: const Key('returnsInfo'),
                tooltip: S.returnsInfoTooltip,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.info_outline, size: 18),
                onPressed: onInfo,
              ),
              PnlText(
                summary.returnsPaise,
                key: const Key('returnsTotal'),
                fraction: summary.returnsFraction,
              ),
            ),
            StatRow(
              S.todayMarket,
              PnlText(
                summary.todayPaise,
                key: const Key('dayChange'),
                fraction: summary.todayFraction,
              ),
            ),
            if (summary.unpricedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(S.unpriced(summary.unpricedCount), style: muted),
              ),
            if (allocation.length > 1) ...[
              const SizedBox(height: 12),
              AllocationBar(shares: allocation),
            ],
            const SizedBox(height: 8),
            Text(
              marketDate == null ? S.footerNoPrices : S.footer(marketDate!),
              key: const Key('summaryFooter'),
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showReturnsInfo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text(S.returns),
    content: const Text(S.returnsInfo),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(S.ok),
      ),
    ],
  ),
);
