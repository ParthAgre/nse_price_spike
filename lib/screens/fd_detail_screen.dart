import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/providers/investment_providers.dart';
import 'package:nse_price_spike/screens/fd_actions.dart';
import 'package:nse_price_spike/screens/fd_form_screen.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';
import 'package:nse_price_spike/widgets/investment_rows.dart';
import 'package:nse_price_spike/widgets/labels.dart';

class FdDetailScreen extends ConsumerWidget {
  final int fdId;

  const FdDetailScreen({super.key, required this.fdId});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FixedDeposit fd,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: S.deleteFdTitle,
      message: S.deleteFdMessage(fd.displayName),
      confirmLabel: S.delete,
    );
    if (!ok) return;
    await ref.read(fixedDepositRepositoryProvider).delete(fd.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return ref
        .watch(fixedDepositProvider(fdId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(S.loadFailed(e))),
          ),
          data: (fd) => fd == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: const Center(child: Text(S.fdNotFound)),
                )
              : _FdDetailView(
                  fd: fd,
                  today: today,
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FdFormScreen(existing: fd),
                    ),
                  ),
                  onCloseEarly: () => closeFdEarly(context, ref, fd),
                  onWithdrawn: () => markFdWithdrawn(context, ref, fd),
                  onRenewed: () => renewFd(context, fd),
                  onDelete: () => _delete(context, ref, fd),
                ),
        );
  }
}

/// Everything about one FD; actions come in as callbacks.
class _FdDetailView extends StatelessWidget {
  final FixedDeposit fd;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onCloseEarly;
  final VoidCallback onWithdrawn;
  final VoidCallback onRenewed;
  final VoidCallback onDelete;

  const _FdDetailView({
    required this.fd,
    required this.today,
    required this.onEdit,
    required this.onCloseEarly,
    required this.onWithdrawn,
    required this.onRenewed,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = fd.terms;
    final status = fd.status(today);
    final total = t.totalDays;
    final elapsed = daysBetween(fd.startDate, today).clamp(0, total).toInt();
    final daysLeft = daysBetween(today, fd.maturityDate);
    final payout = !t.isCumulative;
    final type = payout
        ? S.typePayout(frequencyLabel(t.payoutFrequency))
        : S.typeCumulative(frequencyLabel(t.compounding));
    final realised = fd.realisedInterestPaise;

    return Scaffold(
      appBar: AppBar(
        title: Text(fd.institution),
        actions: [
          if (!fd.isClosed)
            IconButton(
              key: const Key('fdEdit'),
              tooltip: S.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          IconButton(
            key: const Key('fdDelete'),
            tooltip: S.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(fd.displayName, style: theme.textTheme.titleMedium),
          if (status == FdStatus.maturingSoon || status == FdStatus.matured)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(
                  status == FdStatus.matured
                      ? S.chipMatured
                      : S.chipMaturingSoon,
                  urgent: status == FdStatus.matured,
                ),
              ),
            ),
          const SizedBox(height: 12),
          StatRow(S.principalLabel, Text(formatRupees(fd.principalPaise))),
          StatRow(S.rateLabel, Text('${formatRateMilli(t.rateMilliPct)}%')),
          StatRow(S.typeLabel, Text(type)),
          StatRow(
            S.startToMaturity,
            Text(
              '${formatDisplayDate(fd.startDate)} → '
              '${formatDisplayDate(fd.maturityDate)}',
            ),
          ),
          if (!fd.isClosed) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              key: const Key('fdProgress'),
              value: total == 0 ? 0 : elapsed / total,
            ),
            const SizedBox(height: 4),
            Text(
              status == FdStatus.upcoming
                  ? S.startsOn(formatDisplayDate(fd.startDate))
                  : S.daysProgress(elapsed, total),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            StatRow(
              S.valueToday,
              Text(fdValueText(fd, today), key: const Key('fdDetailValue')),
            ),
            StatRow(
              payout ? S.interestReceived : S.interestSoFar,
              Text(
                fdInterestText(fd, today),
                key: const Key('fdDetailInterest'),
                style: TextStyle(
                  color: pnlColor(context, fd.interestSoFarOn(today)),
                ),
              ),
            ),
            if (payout)
              StatRow(
                S.interestPerPeriod,
                Text(
                  '${payoutIsEstimated(t) ? S.approx : ''}'
                  '${formatRupees(payoutPerPeriodPaise(t))}',
                ),
              ),
            StatRow(
              S.maturityAmount,
              Text(
                formatRupees(fd.maturityAmount),
                key: const Key('fdDetailMaturity'),
              ),
            ),
            StatRow(S.daysLeft, Text('${daysLeft < 0 ? 0 : daysLeft}')),
            StatRow(
              S.receiptFigure,
              Text(
                payout
                    ? S.notApplicable
                    : t.receiptMaturityPaise == null
                    ? S.receiptNotEntered
                    : S.receiptInUse,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            StatRow(
              S.status,
              Text(switch (fd.closure) {
                FdClosure.renewed => S.closedRenewed(
                  formatDisplayDate(fd.closedOn ?? fd.maturityDate),
                ),
                FdClosure.closedEarly => S.closedEarly(
                  formatDisplayDate(fd.closedOn ?? today),
                ),
                _ => S.closedWithdrawn(
                  formatDisplayDate(fd.closedOn ?? fd.maturityDate),
                ),
              }),
            ),
            StatRow(
              S.amountReceivedLabel,
              Text(
                fd.amountReceivedPaise == null
                    ? '—'
                    : formatRupees(fd.amountReceivedPaise!),
              ),
            ),
            StatRow(
              S.realisedInterest,
              PnlText(realised, key: const Key('fdRealisedInterest')),
            ),
          ],
          if (fd.draft.notes != null) ...[
            const SizedBox(height: 8),
            StatRow(S.notes, Text(fd.draft.notes!)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status == FdStatus.matured) ...[
                OutlinedButton(
                  key: const Key('fdWithdrawn'),
                  onPressed: onWithdrawn,
                  child: const Text(S.withdrawn),
                ),
                FilledButton.tonal(
                  key: const Key('fdRenewed'),
                  onPressed: onRenewed,
                  child: const Text(S.renewed),
                ),
              ],
              if (status == FdStatus.active || status == FdStatus.maturingSoon)
                OutlinedButton(
                  key: const Key('fdCloseEarly'),
                  onPressed: onCloseEarly,
                  child: const Text(S.closeEarly),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
