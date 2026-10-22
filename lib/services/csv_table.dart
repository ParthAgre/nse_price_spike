import 'package:csv/csv.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';

/// A decoded CSV with columns looked up by (trimmed) header name, never by
/// position. Uses a real CSV parser so quoted fields with commas are safe.
class CsvTable {
  final Map<String, int> _columns;
  final List<List<dynamic>> rows;

  CsvTable._(this._columns, this.rows);

  factory CsvTable.parse(String text) {
    // Strip a UTF-8 BOM if present.
    final body = text.startsWith('﻿') ? text.substring(1) : text;
    final List<List<dynamic>> all;
    try {
      all = Csv(autoDetect: false, skipEmptyLines: true).decode(body);
    } on Object catch (e) {
      throw PriceParseFailure('CSV decode failed: $e');
    }
    if (all.isEmpty) throw const PriceParseFailure('CSV is empty');
    final header = all.first;
    final columns = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      columns.putIfAbsent('${header[i]}'.trim(), () => i);
    }
    return CsvTable._(columns, all.sublist(1));
  }

  Set<String> get headers => _columns.keys.toSet();

  /// Throws [PriceParseFailure] naming every missing column.
  void requireColumns(Iterable<String> names) {
    final missing = names.where((n) => !_columns.containsKey(n)).toList();
    if (missing.isNotEmpty) {
      throw PriceParseFailure('missing column(s): ${missing.join(', ')}');
    }
  }

  int indexOf(String name) => _columns[name]!;

  /// The trimmed cell, or '' when the row is short.
  static String cell(List<dynamic> row, int index) =>
      index < row.length ? '${row[index]}'.trim() : '';
}
