import 'package:flutter/material.dart';
import 'package:nse_price_spike/utils/money.dart';

Color pnlColor(BuildContext context, int? paise) {
  if (paise == null || paise == 0) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
  return paise > 0
      ? Colors.green.shade700
      : Theme.of(context).colorScheme.error;
}

/// "+₹70.00 (+0.58%)" coloured by sign; "—" when [paise] is null.
class PnlText extends StatelessWidget {
  final int? paise;
  final double? fraction;
  final TextStyle? style;

  const PnlText(this.paise, {super.key, this.fraction, this.style});

  @override
  Widget build(BuildContext context) {
    final text = paise == null
        ? '—'
        : fraction == null
        ? formatRupees(paise!, showPlus: true)
        : '${formatRupees(paise!, showPlus: true)} (${formatPercent(fraction)})';
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        color: pnlColor(context, paise),
      ),
    );
  }
}

/// A label on the left and a value on the right, for summary cards.
class StatRow extends StatelessWidget {
  final String label;
  final Widget value;

  const StatRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle.merge(
                textAlign: TextAlign.right,
                child: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
