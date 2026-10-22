import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/services/csv_table.dart';
import 'package:nse_price_spike/utils/instrument_type.dart';

abstract final class EquityListColumns {
  static const symbol = 'SYMBOL';
  static const name = 'NAME OF COMPANY';
  static const series = 'SERIES';
  static const isin = 'ISIN NUMBER';

  static const all = [symbol, name, series, isin];
}

class EquityList {
  /// Rows with an INE/INF ISIN; others are ignored.
  final List<SymbolEntry> entries;
  final int rowsParsed;

  const EquityList(this.entries, this.rowsParsed);
}

/// Parses NSE's EQUITY_L.csv. Its headers have leading spaces
/// (" SERIES", " ISIN NUMBER"), which [CsvTable] trims.
/// Throws [PriceParseFailure] when required columns are missing.
EquityList parseEquityList(String text) {
  final table = CsvTable.parse(text);
  table.requireColumns(EquityListColumns.all);
  final iSymbol = table.indexOf(EquityListColumns.symbol);
  final iName = table.indexOf(EquityListColumns.name);
  final iSeries = table.indexOf(EquityListColumns.series);
  final iIsin = table.indexOf(EquityListColumns.isin);

  final entries = <SymbolEntry>[];
  var parsed = 0;
  for (final row in table.rows) {
    if (row.length == 1 && CsvTable.cell(row, 0).isEmpty) continue;
    parsed++;
    final isin = CsvTable.cell(row, iIsin).toUpperCase();
    final type = instrumentTypeFromIsin(isin);
    if (type == null) continue;
    entries.add(
      SymbolEntry(
        isin: isin,
        symbol: CsvTable.cell(row, iSymbol),
        name: CsvTable.cell(row, iName),
        type: type,
        series: CsvTable.cell(row, iSeries),
      ),
    );
  }
  return EquityList(entries, parsed);
}
