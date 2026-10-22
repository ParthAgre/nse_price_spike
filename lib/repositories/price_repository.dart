import 'package:drift/drift.dart';
import 'package:nse_price_spike/database/app_database.dart';
import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/models/price_quote.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

PriceQuote quoteFromRow(PriceQuoteData r) => PriceQuote(
  instrumentId: r.instrumentId,
  tradeDate: parseDateKey(r.tradeDate)!,
  closePaise: r.closePaise,
  prevClosePaise: r.prevClosePaise,
  source: QuoteSource.fromDb(r.source),
  fetchedAt: r.fetchedAt,
);

class PriceRepository {
  final AppDatabase _db;

  PriceRepository(this._db);

  Future<void> _upsert({
    required int instrumentId,
    required DateTime tradeDate,
    required int closePaise,
    required int? prevClosePaise,
    required QuoteSource source,
    required DateTime fetchedAt,
  }) => _db
      .into(_db.priceQuotes)
      .insert(
        PriceQuotesCompanion.insert(
          instrumentId: instrumentId,
          tradeDate: dateKey(tradeDate),
          closePaise: closePaise,
          prevClosePaise: Value(prevClosePaise),
          source: source.dbValue,
          fetchedAt: fetchedAt,
        ),
        onConflict: DoUpdate(
          (_) => PriceQuotesCompanion(
            closePaise: Value(closePaise),
            prevClosePaise: Value(prevClosePaise),
            fetchedAt: Value(fetchedAt),
          ),
          target: [
            _db.priceQuotes.instrumentId,
            _db.priceQuotes.tradeDate,
            _db.priceQuotes.source,
          ],
        ),
      );

  /// Stores file quotes only for held instruments, matched by ISIN.
  /// Returns how many holdings were matched.
  Future<int> upsertFileQuotes(
    DailyFile file,
    Map<String, int> heldIdsByIsin,
    DateTime fetchedAt,
  ) => _db.transaction(() async {
    var matched = 0;
    for (final MapEntry(key: isin, value: instrumentId)
        in heldIdsByIsin.entries) {
      final row = file.rowsByIsin[isin];
      if (row == null) continue;
      matched++;
      await _upsert(
        instrumentId: instrumentId,
        tradeDate: file.tradeDate,
        closePaise: row.closePaise,
        prevClosePaise: row.prevClosePaise,
        source: QuoteSource.nseBhavcopy,
        fetchedAt: fetchedAt,
      );
    }
    return matched;
  });

  Future<void> setManualPrice({
    required int instrumentId,
    required int closePaise,
    required DateTime tradeDate,
    required DateTime now,
  }) => _upsert(
    instrumentId: instrumentId,
    tradeDate: tradeDate,
    closePaise: closePaise,
    prevClosePaise: null,
    source: QuoteSource.manual,
    fetchedAt: now,
  );

  Future<List<PriceQuote>> quotesFor(Iterable<int> instrumentIds) async {
    final rows = await (_db.select(
      _db.priceQuotes,
    )..where((t) => t.instrumentId.isIn(instrumentIds))).get();
    return rows.map(quoteFromRow).toList();
  }

  /// Newest first.
  Stream<List<PriceQuote>> watchQuotes(int instrumentId) =>
      (_db.select(_db.priceQuotes)
            ..where((t) => t.instrumentId.equals(instrumentId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.tradeDate),
              (t) => OrderingTerm.asc(t.source),
            ]))
          .watch()
          .map((rows) => rows.map(quoteFromRow).toList());

  /// Deletes all file quotes; manual prices are kept.
  Future<void> clearFileQuotes() => (_db.delete(
    _db.priceQuotes,
  )..where((t) => t.source.equals(QuoteSource.nseBhavcopy.dbValue))).go();
}
