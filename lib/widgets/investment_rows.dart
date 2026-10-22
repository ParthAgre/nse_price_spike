import 'package:flutter/material.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';

/// Shared two-column layout: details on the left, figures on the right.
class _RowLayout extends StatelessWidget {
  final List<Widget> left;
  final List<Widget> right;
  final VoidCallback onTap;

  const _RowLayout({
    required this.left,
    required this.right,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: left,
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: right),
          ],
        ),
      ),
    );
  }
}

TextStyle? _muted(BuildContext context) => Theme.of(context).textTheme.bodySmall
    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

/// A stock or ETF: name, symbol, "{qty} shares · avg ₹x"; value and either
/// total returns % or today's change %.
class HoldingRow extends StatelessWidget {
  final MarketItem item;

  /// True: today's change %; false: total returns %.
  final bool showToday;
  final VoidCallback onTap;

  const HoldingRow({
    super.key,
    required this.item,
    required this.showToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = item.holding;
    final avg = h.averageCostPaise;
    final value = item.valuePaise;
    return _RowLayout(
      onTap: onTap,
      left: [
        Text(
          h.instrument.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        Text(h.instrument.symbol, style: _muted(context)),
        const SizedBox(height: 2),
        Text(
          S.sharesLine(
            formatQuantity(h.quantityScaled),
            avg == null ? '—' : formatRupees(avg),
            etf: h.instrument.type == InstrumentType.etf,
          ),
          style: _muted(context),
        ),
      ],
      right: [
        Text(
          value == null ? '—' : formatRupees(value),
          style: theme.textTheme.titleSmall,
        ),
        if (value == null)
          Text(S.noPrice, style: _muted(context))
        else
          PercentText(
            showToday ? item.todayFraction : item.returnsFraction,
            key: const Key('rowPercent'),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// Line 2 of an FD row: "₹x · 7.125% · matures 21 Oct 2027 (365 days)".
String fdDetailLine(FixedDeposit fd, DateTime today) {
  final status = fd.status(today);
  final date = formatDisplayDate(fd.maturityDate);
  final rest = switch (status) {
    FdStatus.upcoming => S.startsOn(formatDisplayDate(fd.startDate)),
    FdStatus.matured || FdStatus.closed => S.maturedOn(date),
    _ => S.maturesIn(date, daysBetween(today, fd.maturityDate)),
  };
  return S.fdLine(
    formatRupees(fd.principalPaise),
    formatRateMilli(fd.draft.rateMilliPct),
    rest,
  );
}

/// The value with "≈" when it is an estimate.
String fdValueText(FixedDeposit fd, DateTime today) {
  final text = formatRupees(fd.valueOn(today));
  return fdValueIsApproximate(fd.terms, today) ? '${S.approx}$text' : text;
}

/// "+₹x" interest so far; "≈" for an estimated payout.
String fdInterestText(FixedDeposit fd, DateTime today) {
  final text = formatRupees(fd.interestSoFarOn(today), showPlus: true);
  final estimated =
      !fd.terms.isCumulative &&
      payoutIsEstimated(fd.terms) &&
      fd.interestSoFarOn(today) != 0;
  return estimated ? '${S.approx}$text' : text;
}

class FdRow extends StatelessWidget {
  final FdItem item;
  final VoidCallback onTap;

  const FdRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fd = item.fd;
    final status = item.status;
    final interest = fd.interestSoFarOn(item.today);
    return _RowLayout(
      onTap: onTap,
      left: [
        Text(
          fd.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(fdDetailLine(fd, item.today), style: _muted(context)),
        if (status == FdStatus.maturingSoon || status == FdStatus.matured)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: StatusChip(
              status == FdStatus.matured ? S.chipMatured : S.chipMaturingSoon,
              key: const Key('fdStatusChip'),
              urgent: status == FdStatus.matured,
            ),
          ),
      ],
      right: [
        Text(
          fdValueText(fd, item.today),
          key: const Key('fdValue'),
          style: theme.textTheme.titleSmall,
        ),
        Text(
          fdInterestText(fd, item.today),
          key: const Key('fdInterest'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: pnlColor(context, interest),
          ),
        ),
      ],
    );
  }
}

/// A matured FD pinned to the top: "Renewed or withdrawn?".
class MaturedFdCard extends StatelessWidget {
  final FdItem item;
  final VoidCallback onTap;
  final VoidCallback onWithdrawn;
  final VoidCallback onRenewed;

  const MaturedFdCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onWithdrawn,
    required this.onRenewed,
  });

  @override
  Widget build(BuildContext context) {
    final id = item.fd.id;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FdRow(item: item, onTap: onTap),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  S.maturedPrompt,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      key: Key('withdrawn-$id'),
                      onPressed: onWithdrawn,
                      child: const Text(S.withdrawn),
                    ),
                    FilledButton.tonal(
                      key: Key('renewed-$id'),
                      onPressed: onRenewed,
                      child: const Text(S.renewed),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A closed FD in the "Closed" section, with its realised interest.
class ClosedFdRow extends StatelessWidget {
  final FdItem item;
  final VoidCallback onTap;

  const ClosedFdRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fd = item.fd;
    final date = formatDisplayDate(fd.closedOn ?? fd.maturityDate);
    final how = switch (fd.closure) {
      FdClosure.renewed => S.closedRenewed(date),
      FdClosure.closedEarly => S.closedEarly(date),
      _ => S.closedWithdrawn(date),
    };
    final realised = fd.realisedInterestPaise;
    return _RowLayout(
      onTap: onTap,
      left: [
        Text(
          fd.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(how, style: _muted(context)),
      ],
      right: [
        Text(S.realisedInterest, style: _muted(context)),
        PnlText(realised, key: const Key('realisedInterest')),
      ],
    );
  }
}
