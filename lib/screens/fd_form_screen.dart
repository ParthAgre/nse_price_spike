import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/providers/investment_providers.dart';
import 'package:nse_price_spike/providers/service_providers.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/fd_validation.dart';
import 'package:nse_price_spike/utils/holding_validation.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';
import 'package:nse_price_spike/widgets/labels.dart';

/// Add a fixed deposit, edit [existing], or renew [renewFrom] (prefilled;
/// saving closes the old FD as renewed and links the two).
class FdFormScreen extends ConsumerStatefulWidget {
  final FixedDeposit? existing;
  final FixedDeposit? renewFrom;

  const FdFormScreen({super.key, this.existing, this.renewFrom})
    : assert(existing == null || renewFrom == null);

  @override
  ConsumerState<FdFormScreen> createState() => _FdFormScreenState();
}

class _FdFormScreenState extends ConsumerState<FdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _institution = TextEditingController();
  final _institutionFocus = FocusNode();
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _years = TextEditingController();
  final _months = TextEditingController();
  final _days = TextEditingController();
  final _receipt = TextEditingController();
  final _payoutAmount = TextEditingController();
  final _nickname = TextEditingController();
  final _notes = TextEditingController();

  late DateTime _start;
  DateTime? _pickedMaturity;
  bool _byDate = false;
  FdInterestType _type = FdInterestType.cumulative;
  FdFrequency _payoutFrequency = FdFrequency.monthly;
  FdFrequency _compounding = FdFrequency.quarterly;
  bool _saving = false;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    final source = widget.existing ?? widget.renewFrom;
    _start = today;
    if (source == null) return;

    final d = source.draft;
    _institution.text = d.institution;
    _nickname.text = d.nickname ?? '';
    _rate.text = formatRateMilli(d.rateMilliPct);
    _type = d.interestType;
    _payoutFrequency = d.payoutFrequency ?? FdFrequency.monthly;
    _compounding = d.compounding;
    final tenure = tenureBetween(d.startDate, d.maturityDate);
    _years.text = '${tenure.years}';
    _months.text = '${tenure.months}';
    _days.text = '${tenure.days}';

    if (widget.existing != null) {
      _principal.text = paiseToInput(d.principalPaise);
      _start = d.startDate;
      _receipt.text = d.receiptMaturityPaise == null
          ? ''
          : paiseToInput(d.receiptMaturityPaise!);
      _payoutAmount.text = d.payoutAmountPaise == null
          ? ''
          : paiseToInput(d.payoutAmountPaise!);
      _notes.text = d.notes ?? '';
    } else {
      // Renewal: the money that comes back is reinvested from the old
      // maturity date. The user confirms the new rate and tenure.
      _principal.text = paiseToInput(source.maturityAmount);
      _start = source.maturityDate;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _institution,
      _principal,
      _rate,
      _years,
      _months,
      _days,
      _receipt,
      _payoutAmount,
      _nickname,
      _notes,
    ]) {
      c.dispose();
    }
    _institutionFocus.dispose();
    super.dispose();
  }

  bool get _cumulative => _type == FdInterestType.cumulative;

  /// The maturity date from the tenure boxes or the picked date.
  DateTime? get _maturity {
    if (_byDate) return _pickedMaturity;
    final t = tryParseTenure(_years.text, _months.text, _days.text);
    if (t == null || (t.years == 0 && t.months == 0 && t.days == 0)) {
      return null;
    }
    return maturityFromTenure(
      _start,
      years: t.years,
      months: t.months,
      days: t.days,
    );
  }

  /// A draft when every required field parses, else null.
  FdDraft? _draft() {
    final principal = tryParseDecimalToPaise(_principal.text);
    final rate = tryParseRateMilli(_rate.text);
    final maturity = _maturity;
    if (principal == null ||
        principal <= 0 ||
        rate == null ||
        rate <= 0 ||
        maturity == null ||
        validateFdDates(_start, maturity) != null) {
      return null;
    }
    return FdDraft(
      institution: _institution.text.trim(),
      nickname: cleanNotes(_nickname.text),
      principalPaise: principal,
      rateMilliPct: rate,
      startDate: _start,
      maturityDate: maturity,
      interestType: _type,
      compounding: _compounding,
      payoutFrequency: _cumulative ? null : _payoutFrequency,
      receiptMaturityPaise: _cumulative
          ? tryParseDecimalToPaise(_receipt.text)
          : null,
      payoutAmountPaise: _cumulative
          ? null
          : tryParseDecimalToPaise(_payoutAmount.text),
      notes: cleanNotes(_notes.text),
    );
  }

  Future<DateTime?> _pickDate(
    DateTime initial,
    DateTime first,
    DateTime last,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
    );
    return picked == null
        ? null
        : DateTime.utc(picked.year, picked.month, picked.day);
  }

  Future<void> _pickStart() async {
    final today = ref.read(todayProvider);
    final picked = await _pickDate(
      _start,
      DateTime.utc(1990),
      addMonthsClamped(today, fdMaxTenureMonths),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickMaturity() async {
    final picked = await _pickDate(
      _pickedMaturity ?? addMonthsClamped(_start, 12),
      _start.add(const Duration(days: 1)),
      addMonthsClamped(_start, fdMaxTenureMonths),
    );
    if (picked != null) setState(() => _pickedMaturity = picked);
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final maturity = _maturity;
    setState(() {
      _dateError = maturity == null
          ? (_byDate ? S.maturityAfterStart : null)
          : validateFdDates(_start, maturity);
    });
    final draft = _draft();
    if (!formOk || _dateError != null || draft == null) return;

    setState(() => _saving = true);
    final repo = ref.read(fixedDepositRepositoryProvider);
    final now = ref.read(clockProvider)();
    try {
      if (widget.existing != null) {
        await repo.edit(widget.existing!.id, draft);
      } else if (widget.renewFrom != null) {
        await repo.renew(widget.renewFrom!, draft, now: now);
      } else {
        await repo.add(draft, now: now);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, S.couldNotSave(e));
      }
    }
  }

  void _changed([Object? _]) => setState(() {});

  InputDecoration _decoration(String label, {String? helper}) =>
      InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions =
        ref.watch(institutionSuggestionsProvider).valueOrNull ?? const [];
    final maturity = _maturity;
    final draft = _draft();
    final title = widget.existing != null
        ? S.editFdTitle
        : widget.renewFrom != null
        ? S.renewFdTitle
        : S.addFdTitle;
    const gap = SizedBox(height: 12);
    final decimal = const TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.renewFrom != null) ...[
              Text(
                S.renewing(widget.renewFrom!.displayName),
                style: theme.textTheme.bodyMedium,
              ),
              gap,
            ],
            RawAutocomplete<String>(
              textEditingController: _institution,
              focusNode: _institutionFocus,
              optionsBuilder: (value) {
                final q = value.text.trim().toLowerCase();
                return suggestions.where(
                  (s) => s.toLowerCase().contains(q) && s.toLowerCase() != q,
                );
              },
              fieldViewBuilder: (context, controller, focus, onSubmit) =>
                  TextFormField(
                    key: const Key('fdInstitutionField'),
                    controller: controller,
                    focusNode: focus,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration(S.institution),
                    validator: (v) => validateInstitution(v ?? ''),
                    onFieldSubmitted: (_) => onSubmit(),
                  ),
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 320,
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final o in options)
                          ListTile(title: Text(o), onTap: () => onSelected(o)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            gap,
            TextFormField(
              key: const Key('fdPrincipalField'),
              controller: _principal,
              decoration: _decoration(S.principal),
              keyboardType: decimal,
              validator: (v) => validatePrincipal(v ?? ''),
              onChanged: _changed,
            ),
            gap,
            TextFormField(
              key: const Key('fdRateField'),
              controller: _rate,
              decoration: _decoration(S.rate),
              keyboardType: decimal,
              validator: (v) => validateRate(v ?? ''),
              onChanged: _changed,
            ),
            gap,
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${S.startDate}: ${formatDisplayDate(_start)}',
                    key: const Key('fdStartText'),
                  ),
                ),
                TextButton(
                  key: const Key('fdStartPick'),
                  onPressed: _pickStart,
                  child: const Text(S.pick),
                ),
              ],
            ),
            gap,
            SegmentedButton<bool>(
              key: const Key('fdModeToggle'),
              segments: const [
                ButtonSegment(value: false, label: Text(S.byTenure)),
                ButtonSegment(value: true, label: Text(S.byMaturityDate)),
              ],
              selected: {_byDate},
              onSelectionChanged: (s) => setState(() {
                // Carry the current maturity across, so nothing is lost.
                final current = _maturity;
                _byDate = s.first;
                if (_byDate) {
                  _pickedMaturity = current;
                } else if (current != null && current.isAfter(_start)) {
                  final t = tenureBetween(_start, current);
                  _years.text = '${t.years}';
                  _months.text = '${t.months}';
                  _days.text = '${t.days}';
                }
              }),
            ),
            gap,
            if (_byDate)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${S.byMaturityDate}: '
                      '${_pickedMaturity == null ? '—' : formatDisplayDate(_pickedMaturity!)}',
                    ),
                  ),
                  TextButton(
                    key: const Key('fdMaturityPick'),
                    onPressed: _pickMaturity,
                    child: const Text(S.pick),
                  ),
                ],
              )
            else
              FormField<void>(
                validator: (_) =>
                    validateTenureFields(_years.text, _months.text, _days.text),
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (final (key, label, c) in [
                          ('fdYearsField', S.years, _years),
                          ('fdMonthsField', S.months, _months),
                          ('fdDaysField', S.days, _days),
                        ]) ...[
                          Expanded(
                            child: TextField(
                              key: Key(key),
                              controller: c,
                              decoration: _decoration(label),
                              keyboardType: TextInputType.number,
                              onChanged: _changed,
                            ),
                          ),
                          if (key != 'fdDaysField') const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              maturity == null || !maturity.isAfter(_start)
                  ? ''
                  : _byDate
                  ? (() {
                      final t = tenureBetween(_start, maturity);
                      return S.tenureDerived(t.years, t.months, t.days);
                    })()
                  : S.maturesOnDerived(formatDisplayDate(maturity)),
              key: const Key('fdDerived'),
              style: theme.textTheme.bodySmall,
            ),
            if (_dateError != null)
              Text(
                _dateError!,
                key: const Key('fdDateError'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            gap,
            Text(S.interestType, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<FdInterestType>(
              key: const Key('fdTypeToggle'),
              segments: const [
                ButtonSegment(
                  value: FdInterestType.cumulative,
                  label: Text(S.cumulative),
                ),
                ButtonSegment(
                  value: FdInterestType.payout,
                  label: Text(S.payout),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            if (!_cumulative) ...[
              gap,
              _FrequencyField(
                key: const Key('fdPayoutFrequency'),
                label: S.payoutFrequency,
                value: _payoutFrequency,
                onChanged: (f) => setState(() => _payoutFrequency = f),
              ),
            ],
            const SizedBox(height: 8),
            ExpansionTile(
              key: const Key('fdMoreDetails'),
              title: const Text(S.moreDetails),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              maintainState: true,
              children: [
                if (_cumulative) ...[
                  _FrequencyField(
                    key: const Key('fdCompounding'),
                    label: S.compounding,
                    value: _compounding,
                    onChanged: (f) => setState(() => _compounding = f),
                  ),
                  gap,
                  TextFormField(
                    key: const Key('fdReceiptField'),
                    controller: _receipt,
                    decoration: _decoration(
                      S.receiptAmount,
                      helper: S.receiptHint,
                    ),
                    keyboardType: decimal,
                    validator: (v) => validateReceiptAmount(
                      v ?? '',
                      tryParseDecimalToPaise(_principal.text),
                    ),
                    onChanged: _changed,
                  ),
                ] else
                  TextFormField(
                    key: const Key('fdPayoutAmountField'),
                    controller: _payoutAmount,
                    decoration: _decoration(S.payoutAmount),
                    keyboardType: decimal,
                    validator: (v) => validateOptionalAmount(v ?? ''),
                    onChanged: _changed,
                  ),
                gap,
                TextFormField(
                  key: const Key('fdNicknameField'),
                  controller: _nickname,
                  decoration: _decoration(S.nickname),
                ),
                gap,
                TextFormField(
                  key: const Key('fdNotesField'),
                  controller: _notes,
                  maxLength: maxNotesLength,
                  maxLines: 3,
                  minLines: 1,
                  decoration: _decoration(S.notes),
                  validator: (v) => validateNotes(v ?? ''),
                ),
              ],
            ),
            if (draft != null) _FdPreview(draft: draft),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('fdSaveButton'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? S.saving : S.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyField extends StatelessWidget {
  final String label;
  final FdFrequency value;
  final ValueChanged<FdFrequency> onChanged;

  const _FrequencyField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<FdFrequency>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final f in FdFrequency.values)
          DropdownMenuItem(value: f, child: Text(frequencyLabel(f))),
      ],
      onChanged: (f) {
        if (f != null) onChanged(f);
      },
    );
  }
}

/// "Matures 21 Oct 2027 · ₹1,07,185.90 · interest ₹7,185.90", plus a note
/// when the receipt figure differs from the app's estimate by over ₹1.
class _FdPreview extends StatelessWidget {
  final FdDraft draft;

  const _FdPreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    final t = draft.terms;
    final theme = Theme.of(context);
    final receipt = t.receiptMaturityPaise;
    final estimate = estimatedMaturityPaise(t);
    final showsEstimate =
        receipt != null &&
        receipt > t.principalPaise &&
        (receipt - estimate).abs() > 100;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.fdPreview(
                formatDisplayDate(t.maturityDate),
                formatRupees(maturityAmountPaise(t)),
                formatRupees(fdInterestAtMaturityPaise(t)),
              ),
              key: const Key('fdPreview'),
              style: theme.textTheme.bodyMedium,
            ),
            if (showsEstimate)
              Text(
                S.usingReceipt(formatRupees(estimate)),
                key: const Key('fdReceiptNote'),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
