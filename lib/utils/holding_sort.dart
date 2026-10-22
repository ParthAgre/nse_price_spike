// Filtering and sorting of the Investments list. Pure.

import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';

enum InvestmentFilter {
  all,
  stocks,
  etfs,
  fds;

  bool includes(AssetClass c) => switch (this) {
    all => true,
    stocks => c == AssetClass.stocks,
    etfs => c == AssetClass.etfs,
    fds => c == AssetClass.fds,
  };

  static InvestmentFilter of(AssetClass c) => switch (c) {
    AssetClass.stocks => stocks,
    AssetClass.etfs => etfs,
    AssetClass.fds => fds,
  };
}

enum InvestmentSort { value, returns, today, name, maturity }

/// "Maturity date" is offered only under the FDs filter.
List<InvestmentSort> sortOptionsFor(InvestmentFilter filter) =>
    filter == InvestmentFilter.fds
    ? InvestmentSort.values
    : InvestmentSort.values.where((s) => s != InvestmentSort.maturity).toList();

/// Maturity date under the FDs filter, current value elsewhere.
InvestmentSort defaultSortFor(InvestmentFilter filter) =>
    filter == InvestmentFilter.fds
    ? InvestmentSort.maturity
    : InvestmentSort.value;

/// The sort actually applied: [chosen] when it is offered for [filter],
/// else the filter's default.
InvestmentSort effectiveSort(InvestmentSort? chosen, InvestmentFilter filter) =>
    chosen != null && sortOptionsFor(filter).contains(chosen)
    ? chosen
    : defaultSortFor(filter);

class ArrangedItems {
  /// Matured FDs waiting for "Renewed or withdrawn?", pinned to the top.
  final List<FdItem> pinned;
  final List<InvestmentItem> items;

  /// Closed FDs, for the collapsible section at the bottom.
  final List<FdItem> closed;

  const ArrangedItems(this.pinned, this.items, this.closed);
}

int _nullsLast(
  Comparable<dynamic>? a,
  Comparable<dynamic>? b, {
  bool desc = false,
}) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return desc ? b.compareTo(a) : a.compareTo(b);
}

int _byName(InvestmentItem a, InvestmentItem b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

int Function(InvestmentItem, InvestmentItem) _comparator(InvestmentSort sort) {
  int primary(InvestmentItem a, InvestmentItem b) => switch (sort) {
    InvestmentSort.value => _nullsLast(a.valuePaise, b.valuePaise, desc: true),
    InvestmentSort.returns => _nullsLast(
      a.returnsFraction,
      b.returnsFraction,
      desc: true,
    ),
    InvestmentSort.today => _nullsLast(
      a.todayFraction,
      b.todayFraction,
      desc: true,
    ),
    InvestmentSort.name => 0,
    InvestmentSort.maturity => _nullsLast(a.maturityDate, b.maturityDate),
  };
  return (a, b) {
    final c = primary(a, b);
    return c != 0 ? c : _byName(a, b);
  };
}

ArrangedItems arrangeItems(
  Iterable<InvestmentItem> all, {
  required InvestmentFilter filter,
  required InvestmentSort sort,
}) {
  final pinned = <FdItem>[];
  final closed = <FdItem>[];
  final items = <InvestmentItem>[];
  for (final item in all) {
    if (!filter.includes(item.assetClass)) continue;
    if (item is FdItem && item.fd.isClosed) {
      closed.add(item);
    } else if (item is FdItem && item.status == FdStatus.matured) {
      pinned.add(item);
    } else {
      items.add(item);
    }
  }
  items.sort(_comparator(sort));
  pinned.sort((a, b) => a.fd.maturityDate.compareTo(b.fd.maturityDate));
  closed.sort(
    (a, b) => (b.fd.closedOn ?? b.fd.maturityDate).compareTo(
      a.fd.closedOn ?? a.fd.maturityDate,
    ),
  );
  return ArrangedItems(pinned, items, closed);
}
