import 'package:flutter/material.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/theme/app_theme.dart';
import 'package:nse_price_spike/utils/money.dart';

Color pnlColor(BuildContext context, int? paise) =>
    GainLossColors.of(context).forSign(paise);

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

  /// Shown right after the label, e.g. an info button.
  final Widget? labelTrailing;

  const StatRow(this.label, this.value, {super.key, this.labelTrailing});

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      // The value keeps its natural width (up to 60% of the row) so figures
      // stay on one line; the label takes the rest and wraps if it must.
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: labelTrailing == null
                  ? labelText
                  : Row(
                      children: [
                        Flexible(child: labelText),
                        labelTrailing!,
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
              child: DefaultTextStyle.merge(
                textAlign: TextAlign.right,
                child: value,
              ),
            ),
          ],
        ),
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
          child: const Text(S.cancel),
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

/// "+9.91%" / "−0.58%" coloured by sign; "—" when unknown.
class PercentText extends StatelessWidget {
  final double? fraction;
  final TextStyle? style;

  const PercentText(this.fraction, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPercent(fraction),
      style: (style ?? const TextStyle()).copyWith(
        color: GainLossColors.of(context).forSign(fraction),
      ),
    );
  }
}

/// A small coloured status label ("Maturing soon", "Matured").
class StatusChip extends StatelessWidget {
  final String label;
  final bool urgent;

  const StatusChip(this.label, {super.key, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: urgent ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: urgent ? scheme.onErrorContainer : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
