import 'package:nse_price_spike/models/instrument.dart';

const maxSearchResults = 30;

/// In-memory search over the symbol master. Lower-cased keys are computed
/// once, so a keystroke is a single linear scan with no allocation per entry.
class SymbolSearchIndex {
  final List<SymbolEntry> _entries;
  final List<String> _symbols;
  final List<String> _names;

  /// Traded value (TtlTrfVal, paise) per entry from the latest bhavcopy;
  /// null when the instrument wasn't in it.
  final List<int?> _tradedValues;

  SymbolSearchIndex(
    Iterable<SymbolEntry> entries, {
    Map<String, int> tradedValueByIsin = const {},
  }) : _entries = List.unmodifiable(entries),
       _symbols = [for (final e in entries) e.symbol.toLowerCase()],
       _names = [for (final e in entries) e.name.toLowerCase()],
       _tradedValues = [for (final e in entries) tradedValueByIsin[e.isin]];

  int get length => _entries.length;

  /// Groups, in order:
  /// 0. exact symbol (or exact ISIN),
  /// 1. symbol prefix,
  /// 2. name contains.
  ///
  /// Within a group: higher traded value in the latest bhavcopy first,
  /// instruments without one after those, then symbol A–Z.
  List<SymbolEntry> search(String query, {int limit = maxSearchResults}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final ranked = <(int, int)>[]; // (group, index)
    for (var i = 0; i < _entries.length; i++) {
      final symbol = _symbols[i];
      final int group;
      if (symbol == q || _entries[i].isin.toLowerCase() == q) {
        group = 0;
      } else if (symbol.startsWith(q)) {
        group = 1;
      } else if (_names[i].contains(q)) {
        group = 2;
      } else {
        continue;
      }
      ranked.add((group, i));
    }

    ranked.sort((a, b) {
      final byGroup = a.$1.compareTo(b.$1);
      if (byGroup != 0) return byGroup;
      final va = _tradedValues[a.$2];
      final vb = _tradedValues[b.$2];
      if (va != vb) {
        if (va == null) return 1;
        if (vb == null) return -1;
        return vb.compareTo(va);
      }
      return _symbols[a.$2].compareTo(_symbols[b.$2]);
    });

    return [for (final r in ranked.take(limit)) _entries[r.$2]];
  }
}
