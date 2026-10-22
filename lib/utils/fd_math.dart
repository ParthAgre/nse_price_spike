// Pure fixed-deposit maths. Money is integer paise everywhere except inside
// the interest formulas, which use doubles and round once, at the end, to
// the nearest paisa (half-up). Dates are date-only UTC values (see
// trading_day.dart), so day differences are exact.
//
// Assumptions (also listed in STATUS.md):
// - Day count is actual/365, even in leap years. Some banks divide by 366
//   for days that fall in a leap year, so values can differ by a few rupees.
// - An FD whose maturity date is before start + 6 calendar months earns
//   SIMPLE interest: P × r × days / 365. Many banks do this for short FDs.
// - Otherwise a cumulative FD compounds: P × (1 + r/n)^(n × days/365),
//   with n = compounding periods per year. Broken periods compound
//   fractionally, which is a smooth approximation of bank practice.
// - A payout FD's value is always the principal; its interest is paid out.

import 'dart:math' as math;

enum FdInterestType { cumulative, payout }

/// Compounding or payout frequency.
enum FdFrequency {
  monthly(12),
  quarterly(4),
  halfYearly(2),
  yearly(1);

  final int perYear;
  const FdFrequency(this.perYear);

  /// Calendar months per period.
  int get months => 12 ~/ perYear;

  static FdFrequency? tryParse(String? value) =>
      values.where((f) => f.name == value).firstOrNull;
}

const fdDaysPerYear = 365;

/// Below this tenure (in calendar months) an FD earns simple interest.
const fdSimpleInterestMonths = 6;

/// The longest tenure accepted (10 years).
const fdMaxTenureMonths = 120;

/// "Maturing soon" = maturity within this many days.
const fdMaturingSoonDays = 30;

/// Thousandths of a percent per unit: 7.125% is stored as 7125.
const fdRateScale = 1000;

/// Adds calendar months, clamping to the month end: 31 Jan + 1 month is
/// 28 Feb (29 Feb in a leap year).
DateTime addMonthsClamped(DateTime date, int months) {
  final index = date.year * 12 + (date.month - 1) + months;
  final year = index ~/ 12;
  final month = index % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, math.min(date.day, lastDay));
}

/// Start + years + months (month-end clamped) + days.
DateTime maturityFromTenure(
  DateTime start, {
  int years = 0,
  int months = 0,
  int days = 0,
}) => addMonthsClamped(start, years * 12 + months).add(Duration(days: days));

int daysBetween(DateTime from, DateTime to) => to.difference(from).inDays;

class Tenure {
  final int years;
  final int months;
  final int days;

  const Tenure(this.years, this.months, this.days);

  int get totalMonths => years * 12 + months;

  @override
  bool operator ==(Object other) =>
      other is Tenure &&
      other.years == years &&
      other.months == months &&
      other.days == days;

  @override
  int get hashCode => Object.hash(years, months, days);

  @override
  String toString() => 'Tenure($years y, $months m, $days d)';
}

/// The tenure that [maturityFromTenure] turns back into [maturity]: the
/// most whole months that fit, then the remaining days.
Tenure tenureBetween(DateTime start, DateTime maturity) {
  var months =
      (maturity.year - start.year) * 12 + (maturity.month - start.month);
  while (months > 0 && addMonthsClamped(start, months).isAfter(maturity)) {
    months--;
  }
  while (!addMonthsClamped(start, months + 1).isAfter(maturity)) {
    months++;
  }
  if (months < 0) months = 0;
  final days = daysBetween(addMonthsClamped(start, months), maturity);
  return Tenure(months ~/ 12, months % 12, days);
}

/// Rounds a positive paise amount to the nearest paisa, half-up.
int roundPaise(double paise) => (paise + 0.5).floor();

/// Everything the maths needs to know about one FD.
class FdTerms {
  final int principalPaise;

  /// 7.125% p.a. = 7125.
  final int rateMilliPct;
  final DateTime startDate;
  final DateTime maturityDate;
  final FdInterestType interestType;

  /// Cumulative only.
  final FdFrequency compounding;

  /// Payout only.
  final FdFrequency payoutFrequency;

  /// The maturity amount printed on the FD receipt (cumulative only).
  final int? receiptMaturityPaise;

  /// The payout per period from the bank (payout only).
  final int? payoutAmountPaise;

  const FdTerms({
    required this.principalPaise,
    required this.rateMilliPct,
    required this.startDate,
    required this.maturityDate,
    this.interestType = FdInterestType.cumulative,
    this.compounding = FdFrequency.quarterly,
    this.payoutFrequency = FdFrequency.monthly,
    this.receiptMaturityPaise,
    this.payoutAmountPaise,
  });

  /// The annual rate as a fraction (7.125% → 0.07125).
  double get rate => rateMilliPct / (100 * fdRateScale);

  int get totalDays => daysBetween(startDate, maturityDate);

  bool get isCumulative => interestType == FdInterestType.cumulative;

  /// True when the maturity date is before start + 6 calendar months.
  bool get usesSimpleInterest => maturityDate.isBefore(
    addMonthsClamped(startDate, fdSimpleInterestMonths),
  );
}

/// The app's formula value (no receipt) after [days] days, unrounded.
double _formulaValue(FdTerms t, int days) {
  final p = t.principalPaise.toDouble();
  if (t.usesSimpleInterest) return p + p * t.rate * days / fdDaysPerYear;
  final n = t.compounding.perYear;
  return p * math.pow(1 + t.rate / n, n * days / fdDaysPerYear);
}

/// The app's own estimate of the maturity amount, ignoring any receipt.
int estimatedMaturityPaise(FdTerms t) => t.isCumulative
    ? roundPaise(_formulaValue(t, t.totalDays))
    : t.principalPaise;

/// What the bank pays back at maturity. Cumulative: the receipt figure if
/// given, else the estimate. Payout: the principal, because the interest has
/// already been paid out.
int maturityAmountPaise(FdTerms t) => t.isCumulative
    ? t.receiptMaturityPaise ?? estimatedMaturityPaise(t)
    : t.principalPaise;

/// Value on [day].
///
/// Cumulative: the principal before the start, the maturity amount on or
/// after maturity, and in between either the receipt-calibrated curve
/// P × (M/P)^(elapsed/total), which passes exactly through the bank's
/// figure M, or the formula with the elapsed days.
/// Payout: always the principal.
int fdValueOnPaise(FdTerms t, DateTime day) {
  if (!t.isCumulative || !day.isAfter(t.startDate)) return t.principalPaise;
  if (!day.isBefore(t.maturityDate)) return maturityAmountPaise(t);
  final elapsed = daysBetween(t.startDate, day);
  final receipt = t.receiptMaturityPaise;
  if (receipt != null) {
    final p = t.principalPaise.toDouble();
    return roundPaise(p * math.pow(receipt / p, elapsed / t.totalDays));
  }
  return roundPaise(_formulaValue(t, elapsed));
}

/// True when [fdValueOnPaise] is an estimate (shown with "≈"): a cumulative
/// FD between its start and maturity.
bool fdValueIsApproximate(FdTerms t, DateTime day) =>
    t.isCumulative && day.isAfter(t.startDate) && day.isBefore(t.maturityDate);

/// Interest per payout period: the bank's figure if given, else
/// P × r / k (k = payouts per year). Banks typically pay slightly less than
/// r/12 for monthly payout (they discount the quarterly rate), so the
/// estimate can be a little high.
int payoutPerPeriodPaise(FdTerms t) =>
    t.payoutAmountPaise ??
    roundPaise(t.principalPaise * t.rate / t.payoutFrequency.perYear);

bool payoutIsEstimated(FdTerms t) => t.payoutAmountPaise == null;

/// Payout periods completed by [day]. Period ends are whole steps of
/// months from the start date (each clamped to its month end), up to the
/// maturity date. A final broken period shorter than one step is not
/// counted.
int completedPayoutPeriods(FdTerms t, DateTime day) {
  final end = day.isBefore(t.maturityDate) ? day : t.maturityDate;
  var periods = 0;
  while (!addMonthsClamped(
    t.startDate,
    (periods + 1) * t.payoutFrequency.months,
  ).isAfter(end)) {
    periods++;
  }
  return periods;
}

/// Payout interest received up to and including [day].
int interestReceivedPaise(FdTerms t, DateTime day) => t.isCumulative
    ? 0
    : completedPayoutPeriods(t, day) * payoutPerPeriodPaise(t);

/// Returns on [day]: value − principal (cumulative) or the interest
/// received so far (payout).
int fdInterestSoFarPaise(FdTerms t, DateTime day) => t.isCumulative
    ? fdValueOnPaise(t, day) - t.principalPaise
    : interestReceivedPaise(t, day);

/// Total interest over the whole tenure.
int fdInterestAtMaturityPaise(FdTerms t) => t.isCumulative
    ? maturityAmountPaise(t) - t.principalPaise
    : completedPayoutPeriods(t, t.maturityDate) * payoutPerPeriodPaise(t);
