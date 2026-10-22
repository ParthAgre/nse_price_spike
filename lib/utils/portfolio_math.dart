// Pure portfolio maths. All money is integer paise; all quantities are
// integers scaled by [quantityScale]. Nothing here rounds except
// [divRound], which is applied once per product so totals stay exact.

import 'package:nse_price_spike/utils/money.dart';

/// One purchase (or opening position) of an instrument.
class Lot {
  final int quantityScaled;
  final int pricePaise;
  final int feesPaise;

  const Lot({
    required this.quantityScaled,
    required this.pricePaise,
    this.feesPaise = 0,
  });
}

/// Integer division rounding half away from zero.
int divRound(int numerator, int denominator) {
  if (denominator == 0) throw ArgumentError('Division by zero');
  final negative = (numerator < 0) != (denominator < 0);
  final n = numerator.abs();
  final d = denominator.abs();
  final q = (n + d ~/ 2) ~/ d;
  return negative ? -q : q;
}

int totalQuantityScaled(Iterable<Lot> lots) =>
    lots.fold(0, (sum, l) => sum + l.quantityScaled);

/// Σ(qty × price), in paise.
int grossCostPaise(Iterable<Lot> lots) => divRound(
  lots.fold(0, (sum, l) => sum + l.quantityScaled * l.pricePaise),
  quantityScale,
);

int totalFeesPaise(Iterable<Lot> lots) =>
    lots.fold(0, (sum, l) => sum + l.feesPaise);

/// invested = Σ(qty × price) + fees.
int investedPaise(Iterable<Lot> lots) =>
    grossCostPaise(lots) + totalFeesPaise(lots);

/// avg cost = Σ(qty × price) / Σqty.
///
/// Fees are deliberately excluded so the average is comparable with the
/// exchange price; they still count in [investedPaise] and so in P&L.
/// Null when the total quantity is zero.
int? averageCostPaise(Iterable<Lot> lots) {
  final qty = totalQuantityScaled(lots);
  if (qty == 0) return null;
  final weighted = lots.fold(
    0,
    (sum, l) => sum + l.quantityScaled * l.pricePaise,
  );
  return divRound(weighted, qty);
}

/// value = qty × close.
int marketValuePaise(int quantityScaled, int closePaise) =>
    divRound(quantityScaled * closePaise, quantityScale);

/// unrealised P&L = value − invested.
int unrealisedPnlPaise(int valuePaise, int investedPaise) =>
    valuePaise - investedPaise;

/// day change = qty × (close − prev close); null without a previous close.
int? dayChangePaise(int quantityScaled, int closePaise, int? prevClosePaise) {
  if (prevClosePaise == null) return null;
  return divRound(
    quantityScaled * (closePaise - prevClosePaise),
    quantityScale,
  );
}

/// [part] / [base] as a fraction for display; null when [base] is zero.
double? fractionOf(int part, int base) => base == 0 ? null : part / base;

/// The per-holding numbers that feed [computeTotals].
class HoldingFigures {
  final int quantityScaled;
  final int investedPaise;
  final int? closePaise;
  final int? prevClosePaise;

  const HoldingFigures({
    required this.quantityScaled,
    required this.investedPaise,
    this.closePaise,
    this.prevClosePaise,
  });

  int? get valuePaise =>
      closePaise == null ? null : marketValuePaise(quantityScaled, closePaise!);

  int? get pnlPaise => valuePaise == null
      ? null
      : unrealisedPnlPaise(valuePaise!, investedPaise);

  int? get dayChange => closePaise == null
      ? null
      : dayChangePaise(quantityScaled, closePaise!, prevClosePaise);
}

class PortfolioTotals {
  /// Σ value of holdings that have a price.
  final int valuePaise;

  /// Σ invested across all holdings, priced or not.
  final int investedPaise;

  /// Σ P&L over priced holdings only.
  final int pnlPaise;

  /// P&L as a fraction of the invested amount of the priced holdings.
  final double? pnlFraction;

  /// Σ day change over holdings that have a previous close.
  final int dayChangePaise;

  /// Day change as a fraction of those holdings' previous value.
  final double? dayChangeFraction;

  final int unpricedCount;

  const PortfolioTotals({
    required this.valuePaise,
    required this.investedPaise,
    required this.pnlPaise,
    required this.pnlFraction,
    required this.dayChangePaise,
    required this.dayChangeFraction,
    required this.unpricedCount,
  });

  static const empty = PortfolioTotals(
    valuePaise: 0,
    investedPaise: 0,
    pnlPaise: 0,
    pnlFraction: null,
    dayChangePaise: 0,
    dayChangeFraction: null,
    unpricedCount: 0,
  );
}

PortfolioTotals computeTotals(Iterable<HoldingFigures> holdings) {
  var value = 0;
  var invested = 0;
  var pricedInvested = 0;
  var pnl = 0;
  var dayChange = 0;
  var prevValue = 0;
  var unpriced = 0;
  for (final h in holdings) {
    invested += h.investedPaise;
    final v = h.valuePaise;
    if (v == null) {
      unpriced++;
      continue;
    }
    value += v;
    pricedInvested += h.investedPaise;
    pnl += v - h.investedPaise;
    final change = h.dayChange;
    if (change != null) {
      dayChange += change;
      prevValue += v - change;
    }
  }
  return PortfolioTotals(
    valuePaise: value,
    investedPaise: invested,
    pnlPaise: pnl,
    pnlFraction: fractionOf(pnl, pricedInvested),
    dayChangePaise: dayChange,
    dayChangeFraction: fractionOf(dayChange, prevValue),
    unpricedCount: unpriced,
  );
}
