enum InstrumentType {
  stock,
  etf;

  String get label => this == stock ? 'Stock' : 'ETF';

  static InstrumentType fromDb(String value) =>
      value == 'etf' ? InstrumentType.etf : InstrumentType.stock;
}

/// A held (or once-held) instrument. The ISIN is its identity; the symbol is
/// for display only because NSE symbols can change.
class Instrument {
  final int id;
  final String isin;
  final String symbol;
  final String name;
  final InstrumentType type;
  final String? series;

  const Instrument({
    required this.id,
    required this.isin,
    required this.symbol,
    required this.name,
    required this.type,
    this.series,
  });
}

/// One row of the local symbol list used by search.
class SymbolEntry {
  final String isin;
  final String symbol;
  final String name;
  final InstrumentType type;
  final String? series;

  const SymbolEntry({
    required this.isin,
    required this.symbol,
    required this.name,
    required this.type,
    this.series,
  });

  @override
  String toString() => 'SymbolEntry($symbol, $isin)';
}
