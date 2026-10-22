import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/providers/refresh_providers.dart';
import 'package:nse_price_spike/providers/repository_providers.dart';
import 'package:nse_price_spike/providers/service_providers.dart';
import 'package:nse_price_spike/utils/holding_validation.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';

/// Add a new entry for [instrument], or edit/delete [existing].
class HoldingFormScreen extends ConsumerStatefulWidget {
  final SymbolEntry instrument;
  final HoldingEntry? existing;

  const HoldingFormScreen({super.key, required this.instrument, this.existing});

  @override
  ConsumerState<HoldingFormScreen> createState() => _HoldingFormScreenState();
}

class _HoldingFormScreenState extends ConsumerState<HoldingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late final TextEditingController _fees;
  DateTime? _date;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _qty = TextEditingController(
      text: e == null ? '' : quantityToInput(e.quantityScaled),
    );
    _price = TextEditingController(
      text: e == null ? '' : paiseToInput(e.pricePaise),
    );
    _fees = TextEditingController(
      text: e == null || e.feesPaise == 0 ? '' : paiseToInput(e.feesPaise),
    );
    _date = e?.date;
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _fees.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = istDate(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(1990),
      lastDate: today,
    );
    if (picked != null) {
      setState(
        () => _date = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final quantity = parseQuantityScaled(_qty.text);
    final price = parseDecimalToPaise(_price.text);
    final fees = _fees.text.trim().isEmpty
        ? 0
        : parseDecimalToPaise(_fees.text);
    final holdings = ref.read(holdingsRepositoryProvider);
    try {
      final existing = widget.existing;
      if (existing != null) {
        await holdings.updateEntry(
          entryId: existing.id,
          quantityScaled: quantity,
          pricePaise: price,
          feesPaise: fees,
          date: _date,
        );
      } else {
        final instrument = await ref
            .read(instrumentRepositoryProvider)
            .upsert(widget.instrument);
        await holdings.addEntry(
          instrumentId: instrument.id,
          quantityScaled: quantity,
          pricePaise: price,
          feesPaise: fees,
          date: _date,
          now: ref.read(clockProvider)(),
        );
        await ref
            .read(refreshControllerProvider.notifier)
            .backfillQuote(instrument.id, instrument.isin);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Could not save: $e');
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete entry?',
      message:
          'This removes this entry of ${widget.instrument.symbol}. '
          'It cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    await ref.read(holdingsRepositoryProvider).deleteEntry(widget.existing!.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.instrument;
    final theme = Theme.of(context);
    final latestFile = ref.watch(latestFileProvider).valueOrNull;
    final fileRow = latestFile?.rowsByIsin[entry.isin];

    final heldPrice = ref
        .watch(holdingsProvider)
        .valueOrNull
        ?.where((h) => h.instrument.isin == entry.isin)
        .firstOrNull
        ?.price;

    final String closeText;
    if (fileRow != null) {
      closeText =
          'Latest close: ${formatRupees(fileRow.closePaise)} '
          '(${formatDisplayDate(latestFile!.tradeDate)})';
    } else if (heldPrice != null) {
      closeText =
          'Latest price: ${formatRupees(heldPrice.closePaise)} '
          '(${formatDisplayDate(heldPrice.tradeDate)})';
    } else {
      closeText = 'Latest close: not known yet';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit entry' : 'Add holding'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(entry.name, style: theme.textTheme.titleMedium),
            Text(
              '${entry.symbol} · ${entry.type.label} · ${entry.isin}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              closeText,
              key: const Key('latestClose'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('quantityField'),
              controller: _qty,
              decoration: InputDecoration(
                labelText: 'Quantity',
                helperText: entry.type == InstrumentType.stock
                    ? 'Whole shares'
                    : 'Units (up to 4 decimals)',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(
                decimal: entry.type == InstrumentType.etf,
              ),
              validator: (v) => validateQuantity(v ?? '', entry.type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('priceField'),
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Average buy price (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) => validatePrice(v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('feesField'),
              controller: _fees,
              decoration: const InputDecoration(
                labelText: 'Fees (₹, optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) => validateFees(v ?? ''),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _date == null
                        ? 'Buy date: none (opening position)'
                        : 'Buy date: ${formatDisplayDate(_date!)}',
                  ),
                ),
                if (_date != null)
                  IconButton(
                    tooltip: 'Clear date',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _date = null),
                  ),
                TextButton(onPressed: _pickDate, child: const Text('Pick')),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('saveButton'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
