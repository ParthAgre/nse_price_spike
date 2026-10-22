import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/providers/investment_providers.dart';
import 'package:nse_price_spike/screens/fd_form_screen.dart';
import 'package:nse_price_spike/widgets/fd_close_dialog.dart';

// FD lifecycle actions shared by the Investments list and the FD detail
// screen.

/// Matured → withdrawn: amount (default the maturity amount) and date.
Future<void> markFdWithdrawn(
  BuildContext context,
  WidgetRef ref,
  FixedDeposit fd,
) async {
  final today = ref.read(todayProvider);
  final result = await showFdCloseDialog(
    context,
    title: S.withdrawn,
    initialAmountPaise: fd.maturityAmount,
    initialDate: fd.maturityDate.isAfter(today) ? today : fd.maturityDate,
    firstDate: fd.startDate,
    lastDate: today,
  );
  if (result == null) return;
  await ref
      .read(fixedDepositRepositoryProvider)
      .close(
        fd.id,
        closure: FdClosure.withdrawn,
        closedOn: result.date,
        amountReceivedPaise: result.amountPaise,
      );
}

/// Matured → renewed: opens the FD form prefilled from [fd]. The old FD is
/// closed (and linked) only when the new one is saved.
Future<void> renewFd(BuildContext context, FixedDeposit fd) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => FdFormScreen(renewFrom: fd)));

/// Closed before maturity: amount (default today's value) and date.
Future<void> closeFdEarly(
  BuildContext context,
  WidgetRef ref,
  FixedDeposit fd,
) async {
  final today = ref.read(todayProvider);
  final result = await showFdCloseDialog(
    context,
    title: S.closeEarly,
    initialAmountPaise: fd.valueOn(today),
    initialDate: today,
    firstDate: fd.startDate,
    lastDate: today,
  );
  if (result == null) return;
  await ref
      .read(fixedDepositRepositoryProvider)
      .close(
        fd.id,
        closure: FdClosure.closedEarly,
        closedOn: result.date,
        amountReceivedPaise: result.amountPaise,
      );
}
