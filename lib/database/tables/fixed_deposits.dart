import 'package:drift/drift.dart';

@DataClassName('FixedDepositData')
class FixedDeposits extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get institution => text()();

  TextColumn get nickname => text().nullable()();

  IntColumn get principalPaise => integer()();

  /// Thousandths of a percent: 7.125% = 7125.
  IntColumn get rateMilliPct => integer()();

  /// `YYYY-MM-DD`.
  TextColumn get startDate => text()();

  /// `YYYY-MM-DD`. Only the date is stored; tenure is an input method.
  TextColumn get maturityDate => text()();

  /// `cumulative` | `payout`.
  TextColumn get interestType => text()();

  /// `monthly` | `quarterly` | `halfYearly` | `yearly`; payout only.
  TextColumn get payoutFrequency => text().nullable()();

  /// Same values; used for cumulative FDs.
  TextColumn get compounding => text()();

  IntColumn get receiptMaturityPaise => integer().nullable()();

  IntColumn get payoutAmountPaise => integer().nullable()();

  /// `open` | `withdrawn` | `renewed` | `closed_early`.
  TextColumn get status => text().withDefault(const Constant('open'))();

  /// `YYYY-MM-DD`.
  TextColumn get closedOn => text().nullable()();

  IntColumn get amountReceivedPaise => integer().nullable()();

  /// The FD this one was renewed into. Not a foreign key, so either FD can
  /// be deleted; the repository clears dangling links.
  IntColumn get renewedIntoId => integer().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}
