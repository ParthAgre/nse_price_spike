import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/providers/refresh_providers.dart';
import 'package:nse_price_spike/providers/repository_providers.dart';
import 'package:nse_price_spike/providers/service_providers.dart';
import 'package:nse_price_spike/utils/holding_validation.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/portfolio_math.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';

/// "Invested ₹11,000 · worth ₹12,090 today (+9.91%)" for the typed
/// quantity, price and charges at [closePaise]; the no-price message when
/// there is no close; null while the inputs don't parse.
String? stockPreviewText({
  required String quantity,
  required String price,
  required String charges,
  required int? closePaise,
}) {
  final qty = tryParseQuantityScaled(quantity);
  final avg = tryParseDecimalToPaise(price);
  final fees = charges.trim().isEmpty ? 0 : tryParseDecimalToPaise(charges);
  if (qty == null || qty <= 0 || avg == null || avg <= 0 || fees == null) {
    return null;
  }
  if (closePaise == null) return S.stockPreviewNoPrice;
  final invested = investedPaise([
    Lot(quantityScaled: qty, pricePaise: avg, feesPaise: fees),
  ]);
  final worth = marketValuePaise(qty, closePaise);
  return S.stockPreview(
    formatRupeesWhole(invested),
    formatRupeesWhole(worth),
    formatPercent(fractionOf(worth - invested, invested)),
  );
}

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
  late final TextEditingController _notes;
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
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date;
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _fees.dispose();
    _notes.dispose();
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
    final notes = cleanNotes(_notes.text);
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
          notes: notes,
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
          notes: notes,
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
        showSnack(context, S.couldNotSave(e));
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: S.deleteEntryTitle,
      message: S.deleteEntryMessage(widget.instrument.symbol),
      confirmLabel: S.delete,
    );
    if (!ok || !mounted) return;
    await ref.read(holdingsRepositoryProvider).deleteEntry(widget.existing!.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _changed([Object? _]) => setState(() {});

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
      closeText = S.latestClose(
        formatRupees(fileRow.closePaise),
        formatDisplayDate(latestFile!.tradeDate),
      );
    } else if (heldPrice != null) {
      closeText = S.latestPrice(
        formatRupees(heldPrice.closePaise),
        formatDisplayDate(heldPrice.tradeDate),
      );
    } else {
      closeText = S.latestCloseUnknown;
    }
    final preview = stockPreviewText(
      quantity: _qty.text,
      price: _price.text,
      charges: _fees.text,
      closePaise: fileRow?.closePaise ?? heldPrice?.closePaise,
    );
    const gap = SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? S.editEntryTitle : S.addStockTitle),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: S.delete,
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
                labelText: S.quantity,
                helperText: entry.type == InstrumentType.stock
                    ? S.wholeShares
                    : S.etfUnits,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(
                decimal: entry.type == InstrumentType.etf,
              ),
              validator: (v) => validateQuantity(v ?? '', entry.type),
              onChanged: _changed,
            ),
            gap,
            TextFormField(
              key: const Key('priceField'),
              controller: _price,
              decoration: const InputDecoration(
                labelText: S.avgBuyPrice,
                helperText: S.avgBuyPriceHint,
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) => validatePrice(v ?? ''),
              onChanged: _changed,
            ),
            if (preview != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  preview,
                  key: const Key('stockPreview'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 4),
            ExpansionTile(
              key: const Key('moreDetails'),
              title: const Text(S.moreDetails),
              tilePadding: EdgeInsets.zero,
              maintainState: true,
              initiallyExpanded:
                  _isEdit &&
                  (_date != null ||
                      widget.existing!.feesPaise != 0 ||
                      widget.existing!.notes != null),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${S.purchaseDate}: '
                            '${_date == null ? '—' : formatDisplayDate(_date!)}',
                          ),
                          if (_date == null)
                            Text(
                              S.purchaseDateBlank,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (_date != null)
                      IconButton(
                        tooltip: S.clearDate,
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _date = null),
                      ),
                    TextButton(
                      key: const Key('purchaseDatePick'),
                      onPressed: _pickDate,
                      child: const Text(S.pick),
                    ),
                  ],
                ),
                gap,
                TextFormField(
                  key: const Key('feesField'),
                  controller: _fees,
                  decoration: const InputDecoration(
                    labelText: S.charges,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => validateFees(v ?? ''),
                  onChanged: _changed,
                ),
                gap,
                TextFormField(
                  key: const Key('notesField'),
                  controller: _notes,
                  maxLength: maxNotesLength,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: S.notes,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => validateNotes(v ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('saveButton'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? S.saving : S.save),
            ),
          ],
        ),
      ),
    );
  }
}
