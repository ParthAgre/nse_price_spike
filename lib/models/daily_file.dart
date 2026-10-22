import 'dart:typed_data';

import 'package:nse_price_spike/models/instrument.dart';

/// One kept row of a bhavcopy: an equity share (INE…01…) or an ETF (INF…),
/// from any series except BL.
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

  /// TtlTrfVal (total traded value) in paise; null when absent. Used only to
  /// rank search results.
  final int? tradedValuePaise;

  const BhavRow({
    required this.isin,
    required this.symbol,
    required this.series,
    required this.name,
    required this.type,
    required this.closePaise,
    required this.prevClosePaise,
    this.tradedValuePaise,
  });
}

/// A parsed bhavcopy for one trading day.
class DailyFile {
  /// TradDt from the file itself, as a date-only UTC value.
  final DateTime tradeDate;

  /// Kept rows only, keyed by ISIN (one row per ISIN).
  final Map<String, BhavRow> rowsByIsin;

  /// Data rows per series (every series, including excluded ones).
  final Map<String, int> seriesCounts;

  /// Kept rows per series (after the ISIN rule and de-duplication).
  final Map<String, int> keptSeriesCounts;

  /// All data rows read from the CSV.
  final int rowsParsed;

  /// Rows dropped because the ISIN is not an equity share or ETF, or the
  /// series is BL.
  final int rowsExcluded;

  /// Rows dropped because a higher-priority series had the same ISIN.
  final int duplicatesDropped;

  /// Rows with an includable ISIN but an unreadable close.
  final int rowsSkipped;

  /// Size of the downloaded body (zip) in bytes.
  final int sizeBytes;

  /// The raw zip, kept so the app can cache it for later look-ups.
  final Uint8List? rawZip;

  /// Modification time of the CSV inside the zip. Zip times carry no time
  /// zone; they are read as IST (NSE's local time) and stored as an instant.
  final DateTime? zipEntryTime;

  /// The HTTP `Last-Modified` header of the download, if any.
  final DateTime? serverLastModified;

  const DailyFile({
    required this.tradeDate,
    required this.rowsByIsin,
    required this.seriesCounts,
    this.keptSeriesCounts = const {},
    required this.rowsParsed,
    this.rowsExcluded = 0,
    this.duplicatesDropped = 0,
    required this.rowsSkipped,
    required this.sizeBytes,
    this.rawZip,
    this.zipEntryTime,
    this.serverLastModified,
  });

  Iterable<BhavRow> get rows => rowsByIsin.values;

  DailyFile withServerLastModified(DateTime? value) => DailyFile(
    tradeDate: tradeDate,
    rowsByIsin: rowsByIsin,
    seriesCounts: seriesCounts,
    keptSeriesCounts: keptSeriesCounts,
    rowsParsed: rowsParsed,
    rowsExcluded: rowsExcluded,
    duplicatesDropped: duplicatesDropped,
    rowsSkipped: rowsSkipped,
    sizeBytes: sizeBytes,
    rawZip: rawZip,
    zipEntryTime: zipEntryTime,
    serverLastModified: value,
  );
}
