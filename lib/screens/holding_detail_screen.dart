import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/providers/repository_providers.dart';
import 'package:nse_price_spike/providers/service_providers.dart';
import 'package:nse_price_spike/screens/holding_form_screen.dart';
import 'package:nse_price_spike/utils/holding_validation.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/portfolio_math.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';

class HoldingDetailScreen extends ConsumerWidget {
  final int instrumentId;

  const HoldingDetailScreen({super.key, required this.instrumentId});

  SymbolEntry _entryOf(Instrument i) => SymbolEntry(
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
        title: const Text('Set manual price'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Price (₹)',
              helperText: 'Dated today. A newer NSE file replaces it.',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => validatePrice(v ?? ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
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
      title: 'Delete holding?',
      message:
          'This removes all ${holding.entries.length} entries of '
          '${holding.instrument.symbol}. It cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await ref
        .read(holdingsRepositoryProvider)
        .deleteHolding(holding.instrument.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holding = ref.watch(holdingProvider(instrumentId));
    final quotes = ref.watch(quoteHistoryProvider(instrumentId));
    final theme = Theme.of(context);

    return holding.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load: $e')),
      ),
      data: (h) {
        if (h == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This holding has no entries.')),
          );
        }
        final price = h.price;
        final avg = h.averageCostPaise;
        return Scaffold(
          appBar: AppBar(
            title: Text(h.instrument.symbol),
            actions: [
              IconButton(
                tooltip: 'Delete holding',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteHolding(context, ref, h),
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
              StatRow('Quantity', Text(formatQuantity(h.quantityScaled))),
              StatRow(
                'Avg cost (excl. fees)',
                Text(avg == null ? '—' : formatRupees(avg)),
              ),
              StatRow(
                'Invested (incl. fees)',
                Text(formatRupees(h.investedPaise)),
              ),
              StatRow(
                price?.source == QuoteSource.manual ? 'Manual price' : 'Close',
                Text(
                  price == null
                      ? '—'
                      : '${formatRupees(price.closePaise)} '
                            '(${formatDisplayDate(price.tradeDate)})',
                ),
              ),
              StatRow(
                'Value',
                Text(h.valuePaise == null ? '—' : formatRupees(h.valuePaise!)),
              ),
              StatRow(
                'Unrealised P&L',
                PnlText(
                  h.pnlPaise,
                  fraction: h.pnlPaise == null
                      ? null
                      : fractionOf(h.pnlPaise!, h.investedPaise),
                ),
              ),
              StatRow("Today's change", PnlText(h.dayChangePaise)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add entry'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HoldingFormScreen(
                          instrument: _entryOf(h.instrument),
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Set manual price'),
                    onPressed: () => _setManualPrice(context, ref, h),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text('Entries', style: theme.textTheme.titleSmall),
              for (final e in h.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    e.date == null
                        ? 'Opening position'
                        : 'Buy · ${formatDisplayDate(e.date!)}',
                  ),
                  subtitle: Text(
                    '${formatQuantity(e.quantityScaled)} @ '
                    '${formatRupees(e.pricePaise)}'
                    '${e.feesPaise == 0 ? '' : ' · fees ${formatRupees(e.feesPaise)}'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HoldingFormScreen(
                        instrument: _entryOf(h.instrument),
                        existing: e,
                      ),
                    ),
                  ),
                ),
              const Divider(height: 32),
              Text('Close history', style: theme.textTheme.titleSmall),
              ...quotes.when(
                loading: () => const [LinearProgressIndicator()],
                error: (e, _) => [Text('Could not load prices: $e')],
                data: (list) => list.isEmpty
                    ? const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No stored prices yet.'),
                        ),
                      ]
                    : [
                        for (final q in list)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(formatDisplayDate(q.tradeDate)),
                            subtitle: Text(
                              q.source == QuoteSource.manual
                                  ? 'Manual'
                                  : 'NSE close · prev '
                                        '${q.prevClosePaise == null ? '—' : formatRupees(q.prevClosePaise!)}',
                            ),
                            trailing: Text(formatRupees(q.closePaise)),
                          ),
                      ],
              ),
            ],
          ),
        );
      },
    );
  }
}
