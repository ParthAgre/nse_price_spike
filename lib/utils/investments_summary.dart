// Combines market holdings (stocks, ETFs) and fixed deposits into one list
// and one set of totals. Pure: today's date is passed in.

import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/utils/portfolio_math.dart';

/// Stocks = INE ISINs, ETFs = INF ISINs (see instrument_type.dart), FDs.
enum AssetClass { stocks, etfs, fds }

/// One row of the Investments list.
sealed class InvestmentItem {
  const InvestmentItem();

  AssetClass get assetClass;
  String get name;

  /// Null for a stock/ETF without a price.
  int? get valuePaise;
  int? get returnsPaise;
  double? get returnsFraction;

  /// Today's change; null for FDs and holdings without a previous close.
  int? get todayPaise => null;
  double? get todayFraction => null;
  DateTime? get maturityDate => null;
}

class MarketItem extends InvestmentItem {
  final Holding holding;

  const MarketItem(this.holding);

  @override
  AssetClass get assetClass => holding.instrument.type == InstrumentType.etf
      ? AssetClass.etfs
      : AssetClass.stocks;

  @override
  String get name => holding.instrument.name;

  @override
  int? get valuePaise => holding.valuePaise;

  @override
  int? get returnsPaise => holding.pnlPaise;

  @override
  double? get returnsFraction => returnsPaise == null
      ? null
      : fractionOf(returnsPaise!, holding.investedPaise);

  @override
  int? get todayPaise => holding.dayChangePaise;

  /// Today's change over yesterday's value (qty × previous close).
  @override
  double? get todayFraction {
    final change = todayPaise;
    final value = valuePaise;
    if (change == null || value == null) return null;
    return fractionOf(change, value - change);
  }
}

class FdItem extends InvestmentItem {
  final FixedDeposit fd;
  final DateTime today;

  const FdItem(this.fd, this.today);

  FdStatus get status => fd.status(today);

  @override
  AssetClass get assetClass => AssetClass.fds;

  @override
  String get name => fd.displayName;

  @override
  int get valuePaise => fd.valueOn(today);

  /// Value − principal (cumulative) or payouts received (payout).
  @override
  int get returnsPaise => fd.interestSoFarOn(today);

  @override
  double? get returnsFraction => fractionOf(returnsPaise, fd.principalPaise);

  @override
  DateTime get maturityDate => fd.maturityDate;
}

class InvestmentsSummary {
  /// Σ value of priced stocks/ETFs + Σ value of open FDs.
  final int currentValuePaise;

  /// Σ invested of all stocks/ETFs (priced or not) + Σ principal of open FDs.
  final int investedPaise;

  /// Σ returns of priced stocks/ETFs + Σ interest so far of open FDs. For a
  /// payout FD that is the interest already paid out, which is not part of
  /// its current value (the value stays the principal).
  final int returnsPaise;

  /// Returns over the invested amount of the priced items.
  final double? returnsFraction;

  /// Stocks and ETFs only: FDs have no daily price.
  final int todayPaise;
  final double? todayFraction;

  /// Current value per class; classes without open holdings are absent.
  final Map<AssetClass, int> valueByClass;

  final int unpricedCount;

  const InvestmentsSummary({
    required this.currentValuePaise,
    required this.investedPaise,
    required this.returnsPaise,
    required this.returnsFraction,
    required this.todayPaise,
    required this.todayFraction,
    required this.valueByClass,
    required this.unpricedCount,
  });

  /// Classes with at least one open holding, in display order.
  List<AssetClass> get heldClasses =>
      AssetClass.values.where(valueByClass.containsKey).toList();

  bool get isEmpty => valueByClass.isEmpty;

  /// Share of current value per held class; empty when the total is 0.
  Map<AssetClass, double> get allocation {
    if (currentValuePaise <= 0) return const {};
    return {
      for (final c in heldClasses) c: valueByClass[c]! / currentValuePaise,
    };
  }
}

/// Closed FDs are excluded from every total.
InvestmentsSummary computeInvestmentsSummary(
  Iterable<Holding> holdings,
  Iterable<FixedDeposit> fds,
  DateTime today,
) {
  final market = computeTotals(holdings.map((h) => h.figures));
  var value = market.valuePaise;
  var invested = market.investedPaise;
  var returns = market.pnlPaise;
  var pricedInvested = 0;
  final byClass = <AssetClass, int>{};

  for (final h in holdings) {
    final item = MarketItem(h);
    byClass.update(
      item.assetClass,
      (v) => v + (item.valuePaise ?? 0),
      ifAbsent: () => item.valuePaise ?? 0,
    );
    if (item.valuePaise != null) pricedInvested += h.investedPaise;
  }
  for (final fd in fds.where((f) => !f.isClosed)) {
    final item = FdItem(fd, today);
    value += item.valuePaise;
    invested += fd.principalPaise;
    pricedInvested += fd.principalPaise;
    returns += item.returnsPaise;
    byClass.update(
      AssetClass.fds,
      (v) => v + item.valuePaise,
      ifAbsent: () => item.valuePaise,
    );
  }

  return InvestmentsSummary(
    currentValuePaise: value,
    investedPaise: invested,
    returnsPaise: returns,
    returnsFraction: fractionOf(returns, pricedInvested),
    todayPaise: market.dayChangePaise,
    todayFraction: market.dayChangeFraction,
    valueByClass: byClass,
    unpricedCount: market.unpricedCount,
  );
}
