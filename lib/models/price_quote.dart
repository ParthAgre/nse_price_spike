enum QuoteSource {
  nseBhavcopy('nse_bhavcopy'),
  manual('manual');

  final String dbValue;
  const QuoteSource(this.dbValue);

  static QuoteSource fromDb(String value) =>
      value == manual.dbValue ? QuoteSource.manual : QuoteSource.nseBhavcopy;
}

class PriceQuote {
  final int instrumentId;
  final DateTime tradeDate;
  final int closePaise;
  final int? prevClosePaise;
  final QuoteSource source;
  final DateTime fetchedAt;

  const PriceQuote({
    required this.instrumentId,
    required this.tradeDate,
    required this.closePaise,
    required this.prevClosePaise,
    required this.source,
    required this.fetchedAt,
  });
}

/// The price a holding is valued at, chosen by [selectEffectivePrice].
class EffectivePrice {
  final int closePaise;

  /// Only set for file prices; a manual price has no day change.
  final int? prevClosePaise;
  final DateTime tradeDate;
  final QuoteSource source;

  const EffectivePrice({
    required this.closePaise,
    required this.prevClosePaise,
    required this.tradeDate,
    required this.source,
  });
}

/// Picks the price to value a holding at from all its stored quotes.
///
/// The latest file quote overrides the latest manual quote only when its
/// trade date is strictly newer; otherwise the manual price stands.
EffectivePrice? selectEffectivePrice(Iterable<PriceQuote> quotes) {
  PriceQuote? file;
  PriceQuote? manual;
  for (final q in quotes) {
    if (q.source == QuoteSource.nseBhavcopy) {
      if (file == null || q.tradeDate.isAfter(file.tradeDate)) file = q;
    } else {
      if (manual == null ||
          q.tradeDate.isAfter(manual.tradeDate) ||
          (q.tradeDate == manual.tradeDate &&
              q.fetchedAt.isAfter(manual.fetchedAt))) {
        manual = q;
      }
    }
  }
  if (manual != null &&
      (file == null || !file.tradeDate.isAfter(manual.tradeDate))) {
    return EffectivePrice(
      closePaise: manual.closePaise,
      prevClosePaise: null,
      tradeDate: manual.tradeDate,
      source: QuoteSource.manual,
    );
  }
  if (file == null) return null;
  return EffectivePrice(
    closePaise: file.closePaise,
    prevClosePaise: file.prevClosePaise,
    tradeDate: file.tradeDate,
    source: QuoteSource.nseBhavcopy,
  );
}
