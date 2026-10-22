import 'package:drift/drift.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/holding.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/repositories/instrument_repository.dart';
import 'package:nse_price_spike/repositories/price_repository.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

/// Holdings are derived from transactions + quotes on every read; nothing
/// about a holding is stored.
class HoldingsRepository {
  final AppDatabase _db;
  final PriceRepository _prices;

  HoldingsRepository(this._db, this._prices);

  HoldingEntry _entryFromRow(InvestmentTransactionData r) => HoldingEntry(
    id: r.id,
    instrumentId: r.instrumentId,
    kind: TransactionKind.fromDb(r.kind),
    quantityScaled: r.quantityScaled,
    pricePaise: r.pricePaise,
    feesPaise: r.feesPaise,
    date: parseDateKey(r.date),
    notes: r.notes,
    createdAt: r.createdAt,
  );

  Future<List<Holding>> loadHoldings() async {
    final txns = _db.investmentTransactions;
    final query =
        _db.select(txns).join([
          innerJoin(
            _db.instruments,
            _db.instruments.id.equalsExp(txns.instrumentId),
          ),
        ])..orderBy([
          OrderingTerm.asc(txns.date, nulls: NullsOrder.first),
          OrderingTerm.asc(txns.id),
        ]);
    final rows = await query.get();

    final instruments = <int, InstrumentData>{};
    final entries = <int, List<HoldingEntry>>{};
    for (final row in rows) {
      final instrument = row.readTable(_db.instruments);
      instruments[instrument.id] = instrument;
      entries
          .putIfAbsent(instrument.id, () => [])
          .add(_entryFromRow(row.readTable(txns)));
    }

    final quotesById = <int, List<PriceQuote>>{};
    for (final q in await _prices.quotesFor(instruments.keys)) {
      quotesById.putIfAbsent(q.instrumentId, () => []).add(q);
    }

    return [
      for (final MapEntry(key: id, value: instrument) in instruments.entries)
        Holding(
          instrument: instrumentFromRow(instrument),
          entries: entries[id]!,
          price: selectEffectivePrice(quotesById[id] ?? const []),
        ),
    ];
  }

  /// Re-emits whenever instruments, transactions or quotes change.
  Stream<List<Holding>> watchHoldings() async* {
    yield await loadHoldings();
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.instruments,
        _db.investmentTransactions,
        _db.priceQuotes,
      ]),
    )) {
      yield await loadHoldings();
    }
  }

  /// ISIN → instrument id for every instrument with at least one entry.
  Future<Map<String, int>> heldInstrumentIdsByIsin() async {
    final query = _db.selectOnly(_db.instruments, distinct: true).join([
      innerJoin(
        _db.investmentTransactions,
        _db.investmentTransactions.instrumentId.equalsExp(_db.instruments.id),
        useColumns: false,
      ),
    ])..addColumns([_db.instruments.isin, _db.instruments.id]);
    final rows = await query.get();
    return {
      for (final r in rows)
        r.read(_db.instruments.isin)!: r.read(_db.instruments.id)!,
    };
  }

  static String _kindFor(DateTime? date) =>
      (date == null ? TransactionKind.opening : TransactionKind.buy).name;

  Future<int> addEntry({
    required int instrumentId,
    required int quantityScaled,
    required int pricePaise,
    required int feesPaise,
    required DateTime? date,
    String? notes,
    required DateTime now,
  }) => _db
      .into(_db.investmentTransactions)
      .insert(
        InvestmentTransactionsCompanion.insert(
          instrumentId: instrumentId,
          kind: _kindFor(date),
          quantityScaled: quantityScaled,
          pricePaise: pricePaise,
          feesPaise: Value(feesPaise),
          date: Value(date == null ? null : dateKey(date)),
          notes: Value(notes),
          createdAt: now,
        ),
      );

  Future<void> updateEntry({
    required int entryId,
    required int quantityScaled,
    required int pricePaise,
    required int feesPaise,
    required DateTime? date,
    String? notes,
  }) =>
      (_db.update(
        _db.investmentTransactions,
      )..where((t) => t.id.equals(entryId))).write(
        InvestmentTransactionsCompanion(
          kind: Value(_kindFor(date)),
          quantityScaled: Value(quantityScaled),
          pricePaise: Value(pricePaise),
          feesPaise: Value(feesPaise),
          date: Value(date == null ? null : dateKey(date)),
          notes: Value(notes),
        ),
      );

  Future<void> deleteEntry(int entryId) => (_db.delete(
    _db.investmentTransactions,
  )..where((t) => t.id.equals(entryId))).go();

  /// Removes every entry of the instrument (the holding disappears).
  Future<void> deleteHolding(int instrumentId) => (_db.delete(
    _db.investmentTransactions,
  )..where((t) => t.instrumentId.equals(instrumentId))).go();
}
