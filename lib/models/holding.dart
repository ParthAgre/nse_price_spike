import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/utils/portfolio_math.dart' as math;

enum TransactionKind {
  opening,
  buy;

  static TransactionKind fromDb(String value) =>
      value == 'buy' ? TransactionKind.buy : TransactionKind.opening;
}

/// One stored entry (opening position or buy) of a holding.
class HoldingEntry {
  final int id;
  final int instrumentId;
  final TransactionKind kind;
  final int quantityScaled;
  final int pricePaise;
  final int feesPaise;

  /// Null for an opening position.
  final DateTime? date;
  final String? notes;
  final DateTime createdAt;

  const HoldingEntry({
    required this.id,
    required this.instrumentId,
    required this.kind,
    required this.quantityScaled,
    required this.pricePaise,
    required this.feesPaise,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  math.Lot get lot => math.Lot(
    quantityScaled: quantityScaled,
    pricePaise: pricePaise,
    feesPaise: feesPaise,
  );
}

/// A holding derived from its entries plus the effective price. Never stored.
class Holding {
  final Instrument instrument;
  final List<HoldingEntry> entries;
  final EffectivePrice? price;

  const Holding({
    required this.instrument,
    required this.entries,
    required this.price,
  });

  Iterable<math.Lot> get _lots => entries.map((e) => e.lot);

  int get quantityScaled => math.totalQuantityScaled(_lots);
  int get investedPaise => math.investedPaise(_lots);
  int? get averageCostPaise => math.averageCostPaise(_lots);

  math.HoldingFigures get figures => math.HoldingFigures(
    quantityScaled: quantityScaled,
    investedPaise: investedPaise,
    closePaise: price?.closePaise,
    prevClosePaise: price?.prevClosePaise,
  );

  int? get valuePaise => figures.valuePaise;
  int? get pnlPaise => figures.pnlPaise;
  int? get dayChangePaise => figures.dayChange;
}

/// Holdings sorted by value, largest first; unpriced holdings last.
List<Holding> sortByValueDesc(Iterable<Holding> holdings) {
  final list = holdings.toList();
  list.sort((a, b) {
    final av = a.valuePaise;
    final bv = b.valuePaise;
    if (av == null && bv == null) {
      return a.instrument.symbol.compareTo(b.instrument.symbol);
    }
    if (av == null) return 1;
    if (bv == null) return -1;
    return bv.compareTo(av);
  });
  return list;
}
