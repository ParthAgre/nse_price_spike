import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/holding_sort.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';

String assetClassLabel(AssetClass c) => switch (c) {
  AssetClass.stocks => S.classStocks,
  AssetClass.etfs => S.classEtfs,
  AssetClass.fds => S.classFds,
};

String filterLabel(InvestmentFilter f) => switch (f) {
  InvestmentFilter.all => S.filterAll,
  InvestmentFilter.stocks => S.classStocks,
  InvestmentFilter.etfs => S.classEtfs,
  InvestmentFilter.fds => S.classFds,
};

String sortLabel(InvestmentSort s) => switch (s) {
  InvestmentSort.value => S.sortValue,
  InvestmentSort.returns => S.sortReturns,
  InvestmentSort.today => S.sortToday,
  InvestmentSort.name => S.sortName,
  InvestmentSort.maturity => S.sortMaturity,
};

String frequencyLabel(FdFrequency f) => switch (f) {
  FdFrequency.monthly => S.monthly,
  FdFrequency.quarterly => S.quarterly,
  FdFrequency.halfYearly => S.halfYearly,
  FdFrequency.yearly => S.yearly,
};
