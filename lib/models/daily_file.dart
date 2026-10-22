import 'dart:typed_data';

import 'package:nse_price_spike/models/instrument.dart';

/// One kept (EQ/BE, INE/INF) row of a bhavcopy.
class BhavRow {
  final String isin;
  final String symbol;
  final String series;
  final String name;
  final InstrumentType type;

  /// ClsPric, the official close. LastPric is never used.
  final int closePaise;

  /// PrvsClsgPric; null when the cell is blank.
  final int? prevClosePaise;

  const BhavRow({
    required this.isin,
    required this.symbol,
    required this.series,
    required this.name,
    required this.type,
    required this.closePaise,
    required this.prevClosePaise,
  });
}

/// A parsed bhavcopy for one trading day.
class DailyFile {
  /// TradDt from the file itself, as a date-only UTC value.
  final DateTime tradeDate;

  /// Kept rows only, keyed by ISIN.
  final Map<String, BhavRow> rowsByIsin;

  /// Data rows per series (every series, including excluded ones).
  final Map<String, int> seriesCounts;

  /// All data rows read from the CSV.
  final int rowsParsed;

  /// Rows in kept series that were dropped (unknown ISIN prefix or bad price).
  final int rowsSkipped;

  /// Size of the downloaded body (zip) in bytes.
  final int sizeBytes;

  /// The raw zip, kept so the app can cache it for later look-ups.
  final Uint8List? rawZip;

  const DailyFile({
    required this.tradeDate,
    required this.rowsByIsin,
    required this.seriesCounts,
    required this.rowsParsed,
    required this.rowsSkipped,
    required this.sizeBytes,
    this.rawZip,
  });

  Iterable<BhavRow> get rows => rowsByIsin.values;
}
