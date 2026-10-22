import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:nse_price_spike/models/daily_file.dart';
import 'package:nse_price_spike/services/csv_table.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';
import 'package:nse_price_spike/utils/instrument_type.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

/// Series kept for now. GB (gold bonds) and every other series are excluded
/// but still counted in [DailyFile.seriesCounts].
const keptSeries = {'EQ', 'BE'};

abstract final class BhavColumns {
  static const tradeDate = 'TradDt';
  static const isin = 'ISIN';
  static const symbol = 'TckrSymb';
  static const series = 'SctySrs';
  static const name = 'FinInstrmNm';
  static const close = 'ClsPric';
  static const prevClose = 'PrvsClsgPric';

  static const all = [tradeDate, isin, symbol, series, name, close, prevClose];
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
  return parseBhavcopyCsv(text, sizeBytes: bytes.length, rawZip: bytes);
}

DailyFile parseBhavcopyCsv(String text, {int? sizeBytes, Uint8List? rawZip}) {
  final table = CsvTable.parse(text);
  table.requireColumns(BhavColumns.all);
  final iDate = table.indexOf(BhavColumns.tradeDate);
  final iIsin = table.indexOf(BhavColumns.isin);
  final iSymbol = table.indexOf(BhavColumns.symbol);
  final iSeries = table.indexOf(BhavColumns.series);
  final iName = table.indexOf(BhavColumns.name);
  final iClose = table.indexOf(BhavColumns.close);
  final iPrev = table.indexOf(BhavColumns.prevClose);

  final rows = <String, BhavRow>{};
  final seriesCounts = <String, int>{};
  var parsed = 0;
  var skipped = 0;
  DateTime? tradeDate;

  for (final row in table.rows) {
    if (row.length == 1 && CsvTable.cell(row, 0).isEmpty) continue;
    parsed++;
    tradeDate ??= parseDateKey(CsvTable.cell(row, iDate));
    final series = CsvTable.cell(row, iSeries);
    seriesCounts[series] = (seriesCounts[series] ?? 0) + 1;
    if (!keptSeries.contains(series)) continue;

    final isin = CsvTable.cell(row, iIsin).toUpperCase();
    final type = instrumentTypeFromIsin(isin);
    final close = tryParseDecimalToPaise(CsvTable.cell(row, iClose));
    if (type == null || close == null) {
      skipped++;
      continue;
    }
    final prevText = CsvTable.cell(row, iPrev);
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
    );
  }

  if (parsed == 0) throw const PriceParseFailure('CSV has no data rows');
  if (tradeDate == null) {
    throw const PriceParseFailure('TradDt is not a YYYY-MM-DD date');
  }

  return DailyFile(
    tradeDate: tradeDate,
    rowsByIsin: rows,
    seriesCounts: seriesCounts,
    rowsParsed: parsed,
    rowsSkipped: skipped,
    sizeBytes: sizeBytes ?? utf8.encode(text).length,
    rawZip: rawZip,
  );
}
