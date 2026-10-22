import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/money.dart';

import 'fixtures.dart';

/// A holding of [qty] units bought at [avgPaise], priced at [closePaise].
Holding holding(
  String symbol, {
  int id = 1,
  InstrumentType type = InstrumentType.stock,
  required int qty,
  required int avgPaise,
  int feesPaise = 0,
  int? closePaise,
  int? prevClosePaise,
  String? name,
}) => Holding(
  instrument: Instrument(
    id: id,
    isin:
        '${type == InstrumentType.etf ? 'INF' : 'INE'}${symbol.padRight(6, '0').substring(0, 6)}01011',
    symbol: symbol,
    name: name ?? '$symbol Limited',
    type: type,
  ),
  entries: [
    HoldingEntry(
      id: id,
      instrumentId: id,
      kind: TransactionKind.opening,
      quantityScaled: qty * quantityScale,
      pricePaise: avgPaise,
      feesPaise: feesPaise,
      date: null,
      createdAt: DateTime.utc(2026),
    ),
  ],
  price: closePaise == null
      ? null
      : EffectivePrice(
          closePaise: closePaise,
          prevClosePaise: prevClosePaise,
          tradeDate: d('2026-10-21'),
          source: QuoteSource.nseBhavcopy,
        ),
);

FixedDeposit fixedDeposit({
  int id = 1,
  String institution = 'HDFC Bank',
  int principal = 10000000,
  int rate = 7000,
  String start = '2026-01-01',
  String maturity = '2027-01-01',
  FdInterestType type = FdInterestType.cumulative,
  int? receipt,
  int? payout,
  FdClosure closure = FdClosure.open,
  String? closedOn,
  int? received,
}) => FixedDeposit(
  id: id,
  draft: FdDraft(
    institution: institution,
    principalPaise: principal,
    rateMilliPct: rate,
    startDate: d(start),
    maturityDate: d(maturity),
    interestType: type,
    payoutFrequency: type == FdInterestType.payout ? FdFrequency.monthly : null,
    receiptMaturityPaise: receipt,
    payoutAmountPaise: payout,
  ),
  closure: closure,
  closedOn: closedOn == null ? null : d(closedOn),
  amountReceivedPaise: received,
  createdAt: DateTime.utc(2026),
);
