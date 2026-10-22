import 'package:flutter/material.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/utils/fd_validation.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

typedef FdCloseResult = ({DateTime date, int amountPaise});

/// Asks for the date and amount received when an FD is withdrawn or
/// closed early. Null when cancelled.
Future<FdCloseResult?> showFdCloseDialog(
  BuildContext context, {
  required String title,
  required int initialAmountPaise,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showDialog<FdCloseResult>(
  context: context,
  builder: (_) => _FdCloseDialog(
    title: title,
    initialAmountPaise: initialAmountPaise,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  ),
);

class _FdCloseDialog extends StatefulWidget {
  final String title;
  final int initialAmountPaise;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _FdCloseDialog({
    required this.title,
    required this.initialAmountPaise,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_FdCloseDialog> createState() => _FdCloseDialogState();
}

class _FdCloseDialogState extends State<_FdCloseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount = TextEditingController(
    text: paiseToInput(widget.initialAmountPaise),
  );
  late DateTime _date = widget.initialDate;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked != null) {
      setState(
        () => _date = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: const Key('amountReceivedField'),
              controller: _amount,
              decoration: const InputDecoration(labelText: S.amountReceived),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) => validateRequiredAmount(v ?? ''),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${S.closedOnLabel}: ${formatDisplayDate(_date)}',
                    key: const Key('closeDateText'),
                  ),
                ),
                TextButton(
                  key: const Key('closeDatePick'),
                  onPressed: _pickDate,
                  child: const Text(S.pick),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(S.cancel),
        ),
        FilledButton(
          key: const Key('closeConfirm'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop((
              date: _date,
              amountPaise: parseDecimalToPaise(_amount.text),
            ));
          },
          child: const Text(S.confirm),
        ),
      ],
    );
  }
}
