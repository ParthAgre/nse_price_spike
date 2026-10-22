import 'package:nse_price_spike/models/instrument.dart';

const maxSearchResults = 30;

/// In-memory search over the symbol master. Lower-cased keys are computed
/// once, so a keystroke is a single linear scan with no allocation per entry.
class SymbolSearchIndex {
  final List<SymbolEntry> _entries;
  final List<String> _symbols;
  final List<String> _names;

  SymbolSearchIndex(Iterable<SymbolEntry> entries)
    : _entries = List.unmodifiable(entries),
      _symbols = [for (final e in entries) e.symbol.toLowerCase()],
      _names = [for (final e in entries) e.name.toLowerCase()];

  int get length => _entries.length;

  /// Ranking: exact ISIN, then symbol prefix, then symbol contains, then
  /// name contains. Within a rank, shorter symbols first, then alphabetical.
  List<SymbolEntry> search(String query, {int limit = maxSearchResults}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final ranked = <(int, int)>[]; // (rank, index)
    for (var i = 0; i < _entries.length; i++) {
      final symbol = _symbols[i];
      final int rank;
      if (_entries[i].isin.toLowerCase() == q) {
        rank = 0;
      } else if (symbol.startsWith(q)) {
        rank = 1;
      } else if (symbol.contains(q)) {
        rank = 2;
      } else if (_names[i].contains(q)) {
        rank = 3;
      } else {
        continue;
      }
      ranked.add((rank, i));
    }

    ranked.sort((a, b) {
      final byRank = a.$1.compareTo(b.$1);
      if (byRank != 0) return byRank;
      final sa = _symbols[a.$2];
      final sb = _symbols[b.$2];
      final byLength = sa.length.compareTo(sb.length);
      return byLength != 0 ? byLength : sa.compareTo(sb);
    });

    return [for (final r in ranked.take(limit)) _entries[r.$2]];
  }
}
