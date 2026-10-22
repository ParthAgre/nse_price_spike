import 'package:nse_price_spike/utils/fd_math.dart';

/// How a fixed deposit ended. Stored; everything else about status is
/// derived from dates.
enum FdClosure {
  open('open'),
  withdrawn('withdrawn'),
  renewed('renewed'),
  closedEarly('closed_early');

  final String dbValue;
  const FdClosure(this.dbValue);

  static FdClosure fromDb(String value) =>
      values.firstWhere((c) => c.dbValue == value, orElse: () => open);
}

enum FdStatus { upcoming, active, maturingSoon, matured, closed }

/// Upcoming: starts after [today]. Matured: [today] is on or after maturity
/// and it isn't closed. Maturing soon: maturity within 30 days.
FdStatus deriveFdStatus({
  required DateTime startDate,
  required DateTime maturityDate,
  required FdClosure closure,
  required DateTime today,
}) {
  if (closure != FdClosure.open) return FdStatus.closed;
  if (today.isBefore(startDate)) return FdStatus.upcoming;
  if (!today.isBefore(maturityDate)) return FdStatus.matured;
  if (daysBetween(today, maturityDate) <= fdMaturingSoonDays) {
    return FdStatus.maturingSoon;
  }
  return FdStatus.active;
}

/// The user-editable fields of an FD (the form's output).
class FdDraft {
  final String institution;
  final String? nickname;
  final int principalPaise;
  final int rateMilliPct;
  final DateTime startDate;
  final DateTime maturityDate;
  final FdInterestType interestType;
  final FdFrequency compounding;
  final FdFrequency? payoutFrequency;
  final int? receiptMaturityPaise;
  final int? payoutAmountPaise;
  final String? notes;

  const FdDraft({
    required this.institution,
    this.nickname,
    required this.principalPaise,
    required this.rateMilliPct,
    required this.startDate,
    required this.maturityDate,
    this.interestType = FdInterestType.cumulative,
    this.compounding = FdFrequency.quarterly,
    this.payoutFrequency,
    this.receiptMaturityPaise,
    this.payoutAmountPaise,
    this.notes,
  });

  FdTerms get terms => FdTerms(
    principalPaise: principalPaise,
    rateMilliPct: rateMilliPct,
    startDate: startDate,
    maturityDate: maturityDate,
    interestType: interestType,
    compounding: compounding,
    payoutFrequency: payoutFrequency ?? FdFrequency.monthly,
    receiptMaturityPaise: interestType == FdInterestType.cumulative
        ? receiptMaturityPaise
        : null,
    payoutAmountPaise: interestType == FdInterestType.payout
        ? payoutAmountPaise
        : null,
  );
}

/// A stored fixed deposit.
class FixedDeposit {
  final int id;
  final FdDraft draft;
  final FdClosure closure;
  final DateTime? closedOn;
  final int? amountReceivedPaise;

  /// The FD this one was renewed into.
  final int? renewedIntoId;
  final DateTime createdAt;

  const FixedDeposit({
    required this.id,
    required this.draft,
    this.closure = FdClosure.open,
    this.closedOn,
    this.amountReceivedPaise,
    this.renewedIntoId,
    required this.createdAt,
  });

  String get institution => draft.institution;
  String? get nickname => draft.nickname;
  int get principalPaise => draft.principalPaise;
  DateTime get startDate => draft.startDate;
  DateTime get maturityDate => draft.maturityDate;
  FdTerms get terms => draft.terms;
  bool get isClosed => closure != FdClosure.open;

  /// "HDFC Bank · Emergency fund", or just the institution.
  String get displayName {
    final nick = nickname?.trim() ?? '';
    return nick.isEmpty ? institution : '$institution · $nick';
  }

  FdStatus status(DateTime today) => deriveFdStatus(
    startDate: startDate,
    maturityDate: maturityDate,
    closure: closure,
    today: today,
  );

  int valueOn(DateTime today) => fdValueOnPaise(terms, today);

  int interestSoFarOn(DateTime today) => fdInterestSoFarPaise(terms, today);

  int get maturityAmount => maturityAmountPaise(terms);

  /// What actually came back, for a closed FD: received − principal, plus
  /// any payouts received before it closed. Lower than the accrued value
  /// when the bank charged a premature-withdrawal penalty.
  int? get realisedInterestPaise {
    final received = amountReceivedPaise;
    if (!isClosed || received == null) return null;
    final payouts = closedOn == null
        ? 0
        : interestReceivedPaise(terms, closedOn!);
    return received - principalPaise + payouts;
  }
}
