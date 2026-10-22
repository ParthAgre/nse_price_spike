import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/repositories/fixed_deposit_repository.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

import 'database_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

final fixedDepositRepositoryProvider = Provider<FixedDepositRepository>(
  (ref) => FixedDepositRepository(ref.read(appDatabaseProvider)),
);

/// Today's IST date: FD values and statuses are computed for it.
final todayProvider = Provider<DateTime>(
  (ref) => istDate(ref.watch(clockProvider)()),
);

final fixedDepositsProvider = StreamProvider<List<FixedDeposit>>((ref) {
  return ref.read(fixedDepositRepositoryProvider).watchAll();
});

final fixedDepositProvider = Provider.family<AsyncValue<FixedDeposit?>, int>((
  ref,
  id,
) {
  return ref
      .watch(fixedDepositsProvider)
      .whenData((list) => list.where((fd) => fd.id == id).firstOrNull);
});

final institutionSuggestionsProvider = StreamProvider<List<String>>((ref) {
  return ref.read(fixedDepositRepositoryProvider).watchInstitutions();
});

/// Every row of the Investments list: stocks/ETFs and FDs (closed ones too).
final investmentItemsProvider = Provider<AsyncValue<List<InvestmentItem>>>((
  ref,
) {
  final holdings = ref.watch(holdingsProvider);
  final fds = ref.watch(fixedDepositsProvider);
  final today = ref.watch(todayProvider);
  if (holdings.hasError) {
    return AsyncError(holdings.error!, holdings.stackTrace!);
  }
  if (fds.hasError) return AsyncError(fds.error!, fds.stackTrace!);
  if (!holdings.hasValue || !fds.hasValue) return const AsyncLoading();
  return AsyncData([
    for (final h in holdings.value!) MarketItem(h),
    for (final fd in fds.value!) FdItem(fd, today),
  ]);
});

final investmentsSummaryProvider = Provider<AsyncValue<InvestmentsSummary>>((
  ref,
) {
  final holdings = ref.watch(holdingsProvider);
  final fds = ref.watch(fixedDepositsProvider);
  final today = ref.watch(todayProvider);
  if (!holdings.hasValue || !fds.hasValue) return const AsyncLoading();
  return AsyncData(
    computeInvestmentsSummary(holdings.value!, fds.value!, today),
  );
});
