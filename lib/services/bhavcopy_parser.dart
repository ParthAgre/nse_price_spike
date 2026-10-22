import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/services/csv_table.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';
import 'package:nse_price_spike/utils/instrument_type.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

/// Rows are kept by ISIN (see [instrumentTypeFromIsin]), not by series. The
/// one series always excluded is BL, the block-deal window: it repeats ISINs
/// that also trade in EQ, at different closes.
const excludedSeries = {'BL'};

/// When one ISIN appears in several kept series, the row from the earliest
/// series here wins; unlisted series rank after these, A–Z.
const seriesPriority = ['EQ', 'BE', 'BZ', 'SM', 'ST'];

int _seriesRank(String series) {
  final i = seriesPriority.indexOf(series);
  return i == -1 ? seriesPriority.length : i;
}

/// True when [candidate] should replace [current] for the same ISIN.
bool _outranks(String candidate, String current) {
  final byRank = _seriesRank(candidate).compareTo(_seriesRank(current));
  return byRank != 0 ? byRank < 0 : candidate.compareTo(current) < 0;
}

abstract final class BhavColumns {
  static const tradeDate = 'TradDt';
  static const isin = 'ISIN';
  static const symbol = 'TckrSymb';
  static const series = 'SctySrs';
  static const name = 'FinInstrmNm';
  static const close = 'ClsPric';
  static const prevClose = 'PrvsClsgPric';

  /// Optional: only used to rank search results.
  static const tradedValue = 'TtlTrfVal';

  static const all = [tradeDate, isin, symbol, series, name, close, prevClose];
}

/// A zip entry's DOS timestamp (no zone) read as IST, as an instant.
DateTime? _zipEntryTime(ArchiveFile entry) {
  try {
    final wall = entry.lastModDateTime;
    if (wall.year < 1990) return null;
    return wall.subtract(istOffset);
  } on Object {
    return null;
  }
}

/// True when [bytes] start with a zip signature (local file header, or the
/// end-of-central-directory record of an empty zip).
bool looksLikeZip(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4B &&
    ((bytes[2] == 0x03 && bytes[3] == 0x04) ||
        (bytes[2] == 0x05 && bytes[3] == 0x06));

/// A short printable preview of a non-zip body, for error messages.
String bodyPreview(List<int> bytes, {int max = 60}) {
  final text = utf8.decode(
    bytes.length > max * 4 ? bytes.sublist(0, max * 4) : bytes,
    allowMalformed: true,
  );
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length > max ? '${flat.substring(0, max)}…' : flat;
}

/// Unzips a bhavcopy and parses its CSV. Throws [PriceNotAZip] or
/// [PriceParseFailure].
DailyFile parseBhavcopyZip(Uint8List bytes) {
  if (!looksLikeZip(bytes)) throw PriceNotAZip(bodyPreview(bytes));
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object catch (e) {
    throw PriceParseFailure('corrupt zip: $e');
  }
  final csvEntry = archive.files
      .where((f) => f.isFile && f.name.toLowerCase().endsWith('.csv'))
      .firstOrNull;
  if (csvEntry == null) throw const PriceParseFailure('zip has no CSV file');
  final text = utf8.decode(csvEntry.content, allowMalformed: true);
  return parseBhavcopyCsv(
    text,
    sizeBytes: bytes.length,
    rawZip: bytes,
    zipEntryTime: _zipEntryTime(csvEntry),
  );
}

DailyFile parseBhavcopyCsv(
  String text, {
  int? sizeBytes,
  Uint8List? rawZip,
  DateTime? zipEntryTime,
}) {
  final table = CsvTable.parse(text);
  table.requireColumns(BhavColumns.all);
  final iDate = table.indexOf(BhavColumns.tradeDate);
  final iIsin = table.indexOf(BhavColumns.isin);
  final iSymbol = table.indexOf(BhavColumns.symbol);
  final iSeries = table.indexOf(BhavColumns.series);
  final iName = table.indexOf(BhavColumns.name);
  final iClose = table.indexOf(BhavColumns.close);
  final iPrev = table.indexOf(BhavColumns.prevClose);
  final iValue = table.headers.contains(BhavColumns.tradedValue)
      ? table.indexOf(BhavColumns.tradedValue)
      : null;

  final rows = <String, BhavRow>{};
  final seriesCounts = <String, int>{};
  var parsed = 0;
  var excluded = 0;
  var duplicates = 0;
  var skipped = 0;
  DateTime? tradeDate;

  for (final row in table.rows) {
    if (row.length == 1 && CsvTable.cell(row, 0).isEmpty) continue;
    parsed++;
    tradeDate ??= parseDateKey(CsvTable.cell(row, iDate));
    final series = CsvTable.cell(row, iSeries);
    seriesCounts[series] = (seriesCounts[series] ?? 0) + 1;

    final isin = CsvTable.cell(row, iIsin).toUpperCase();
    final type = instrumentTypeFromIsin(isin);
    if (type == null || excludedSeries.contains(series)) {
      excluded++;
      continue;
    }
    final close = tryParseDecimalToPaise(CsvTable.cell(row, iClose));
    if (close == null) {
      skipped++;
      continue;
    }
    final existing = rows[isin];
    if (existing != null) {
      duplicates++;
      if (!_outranks(series, existing.series)) continue;
    }
    final prevText = CsvTable.cell(row, iPrev);
    final valueText = iValue == null ? '' : CsvTable.cell(row, iValue);
    rows[isin] = BhavRow(
      isin: isin,
      symbol: CsvTable.cell(row, iSymbol),
      series: series,
      name: CsvTable.cell(row, iName),
      type: type,
      closePaise: close,
      prevClosePaise: prevText.isEmpty
          ? null
          : tryParseDecimalToPaise(prevText),
      tradedValuePaise: valueText.isEmpty
          ? null
          : tryParseDecimalToPaise(valueText),
    );
  }

  final keptSeriesCounts = <String, int>{};
  for (final r in rows.values) {
    keptSeriesCounts[r.series] = (keptSeriesCounts[r.series] ?? 0) + 1;
  }

  if (parsed == 0) throw const PriceParseFailure('CSV has no data rows');
  if (tradeDate == null) {
    throw const PriceParseFailure('TradDt is not a YYYY-MM-DD date');
  }

  return DailyFile(
    tradeDate: tradeDate,
    rowsByIsin: rows,
    seriesCounts: seriesCounts,
    keptSeriesCounts: keptSeriesCounts,
    rowsParsed: parsed,
    rowsExcluded: excluded,
    duplicatesDropped: duplicates,
    rowsSkipped: skipped,
    sizeBytes: sizeBytes ?? utf8.encode(text).length,
    rawZip: rawZip,
    zipEntryTime: zipEntryTime,
  );
}
