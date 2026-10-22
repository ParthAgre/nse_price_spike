import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/providers/repository_providers.dart';
import 'package:nse_price_spike/providers/service_providers.dart';
import 'package:nse_price_spike/screens/holding_form_screen.dart';
import 'package:nse_price_spike/utils/holding_validation.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';
import 'package:nse_price_spike/widgets/price_history_chart.dart';

class HoldingDetailScreen extends ConsumerWidget {
  final int instrumentId;

  const HoldingDetailScreen({super.key, required this.instrumentId});

  static SymbolEntry entryOf(Instrument i) => SymbolEntry(
    isin: i.isin,
    symbol: i.symbol,
    name: i.name,
    type: i.type,
    series: i.series,
  );

  Future<void> _setManualPrice(
    BuildContext context,
    WidgetRef ref,
    Holding holding,
  ) async {
    final controller = TextEditingController(
      text: holding.price == null
          ? ''
          : paiseToInput(holding.price!.closePaise),
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(S.setManualPrice),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: S.priceField,
              helperText: S.manualPriceHelper,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => validatePrice(v ?? ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text(S.save),
          ),
        ],
      ),
    );
    if (saved == true) {
      final now = ref.read(clockProvider)();
      await ref
          .read(priceRepositoryProvider)
          .setManualPrice(
            instrumentId: holding.instrument.id,
            closePaise: parseDecimalToPaise(controller.text),
            tradeDate: istDate(now),
            now: now,
          );
    }
    controller.dispose();
  }

  Future<void> _deleteHolding(
    BuildContext context,
    WidgetRef ref,
    Holding holding,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: S.deleteHoldingTitle,
      message: S.deleteHoldingMessage(
        holding.entries.length,
        holding.instrument.symbol,
      ),
      confirmLabel: S.delete,
    );
    if (!ok) return;
    await ref
        .read(holdingsRepositoryProvider)
        .deleteHolding(holding.instrument.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    Holding holding,
    HoldingEntry entry,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: S.deleteEntryTitle,
      message: S.deleteEntryMessage(holding.instrument.symbol),
      confirmLabel: S.delete,
    );
    if (ok) await ref.read(holdingsRepositoryProvider).deleteEntry(entry.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holding = ref.watch(holdingProvider(instrumentId));
    final quotes = ref.watch(quoteHistoryProvider(instrumentId));

    return holding.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(S.loadFailed(e))),
      ),
      data: (h) {
        if (h == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text(S.noEntries)),
          );
        }
        void push(Widget screen) => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => screen));
        return _HoldingDetailView(
          holding: h,
          quotes: quotes.valueOrNull ?? const [],
          onDeleteHolding: () => _deleteHolding(context, ref, h),
          onAddEntry: () =>
              push(HoldingFormScreen(instrument: entryOf(h.instrument))),
          onEditEntry: (e) => push(
            HoldingFormScreen(instrument: entryOf(h.instrument), existing: e),
          ),
          onDeleteEntry: (e) => _deleteEntry(context, ref, h, e),
          onSetManualPrice: () => _setManualPrice(context, ref, h),
        );
      },
    );
  }
}

class _HoldingDetailView extends StatelessWidget {
  final Holding holding;

  /// Newest first.
  final List<PriceQuote> quotes;
  final VoidCallback onDeleteHolding;
  final VoidCallback onAddEntry;
  final ValueChanged<HoldingEntry> onEditEntry;
  final ValueChanged<HoldingEntry> onDeleteEntry;
  final VoidCallback onSetManualPrice;

  const _HoldingDetailView({
    required this.holding,
    required this.quotes,
    required this.onDeleteHolding,
    required this.onAddEntry,
    required this.onEditEntry,
    required this.onDeleteEntry,
    required this.onSetManualPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = holding;
    final item = MarketItem(h);
    final price = h.price;
    final avg = h.averageCostPaise;
    final fileCloses = [
      for (final q in quotes)
        if (q.source == QuoteSource.nseBhavcopy) (q.tradeDate, q.closePaise),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(h.instrument.symbol),
        actions: [
          IconButton(
            tooltip: S.deleteHolding,
            icon: const Icon(Icons.delete_outline),
            onPressed: onDeleteHolding,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(h.instrument.name, style: theme.textTheme.titleMedium),
          Text(
            '${h.instrument.type.label} · ${h.instrument.isin}'
            '${h.instrument.series == null ? '' : ' · ${h.instrument.series}'}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          StatRow(
            S.currentValue,
            Text(
              h.valuePaise == null ? '—' : formatRupees(h.valuePaise!),
              key: const Key('detailValue'),
            ),
          ),
          StatRow(
            S.returns,
            PnlText(h.pnlPaise, fraction: item.returnsFraction),
          ),
          StatRow(
            S.today,
            PnlText(h.dayChangePaise, fraction: item.todayFraction),
          ),
          StatRow(S.quantity, Text(formatQuantity(h.quantityScaled))),
          StatRow(
            S.avgBuyPriceShort,
            Text(avg == null ? '—' : formatRupees(avg)),
          ),
          StatRow(S.investedInclCharges, Text(formatRupees(h.investedPaise))),
          StatRow(
            price?.source == QuoteSource.manual
                ? S.manualPriceLabel
                : S.latestCloseLabel,
            Text(
              price == null
                  ? '—'
                  : '${formatRupees(price.closePaise)} '
                        '(${formatDisplayDate(price.tradeDate)})',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: const Text(S.addEntry),
                onPressed: onAddEntry,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text(S.setManualPrice),
                onPressed: onSetManualPrice,
              ),
            ],
          ),
          if (fileCloses.length >= 2) ...[
            const Divider(height: 32),
            PriceHistoryChart(points: fileCloses),
          ],
          const Divider(height: 32),
          Text(S.entries, style: theme.textTheme.titleSmall),
          for (final e in h.entries)
            ListTile(
              key: Key('entry-${e.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                e.date == null
                    ? S.openingPosition
                    : S.boughtOn(formatDisplayDate(e.date!)),
              ),
              subtitle: Text(
                S.entryLine(
                      formatQuantity(e.quantityScaled),
                      formatRupees(e.pricePaise),
                      e.feesPaise == 0 ? null : formatRupees(e.feesPaise),
                    ) +
                    (e.notes == null ? '' : '\n${e.notes}'),
              ),
              onTap: () => onEditEntry(e),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: S.edit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => onEditEntry(e),
                  ),
                  IconButton(
                    key: Key('deleteEntry-${e.id}'),
                    tooltip: S.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDeleteEntry(e),
                  ),
                ],
              ),
            ),
          const Divider(height: 32),
          Text(S.closeHistory, style: theme.textTheme.titleSmall),
          if (quotes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(S.noStoredPrices),
            ),
          for (final q in quotes)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(formatDisplayDate(q.tradeDate)),
              subtitle: Text(
                q.source == QuoteSource.manual
                    ? S.manual
                    : S.nseClosePrev(
                        q.prevClosePaise == null
                            ? '—'
                            : formatRupees(q.prevClosePaise!),
                      ),
              ),
              trailing: Text(formatRupees(q.closePaise)),
            ),
        ],
      ),
    );
  }
}
