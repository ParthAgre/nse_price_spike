import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/fixed_deposit.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/utils/holding_sort.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';

import '../helpers/fixtures.dart';
import '../helpers/investments.dart';

void main() {
  final today = d('2026-10-21');
  // Value 12,090; returns +9.91%; today +0.58%.
  final reliance = MarketItem(
    holding(
      'RELIANCE',
      id: 1,
      qty: 10,
      avgPaise: 110000,
      closePaise: 120900,
      prevClosePaise: 120200,
      name: 'Reliance Industries',
    ),
  );
  // Value 3,000; returns −25%; today −2.91%.
  final abc = MarketItem(
    holding(
      'ABC',
      id: 2,
      qty: 10,
      avgPaise: 40000,
      closePaise: 30000,
      prevClosePaise: 30900,
      name: 'Abc Ltd',
    ),
  );
  // ETF: value 25,957; returns +3.83%; today −0.17%.
  final bees = MarketItem(
    holding(
      'NIFTYBEES',
      id: 3,
      type: InstrumentType.etf,
      qty: 100,
      avgPaise: 25000,
      closePaise: 25957,
      prevClosePaise: 26000,
      name: 'Nippon Nifty BeES',
    ),
  );
  final unpriced = MarketItem(
    holding('ZED', id: 4, qty: 1, avgPaise: 100, name: 'Zed Co'),
  );
  // FD maturing 1 Jan 2027 (value ≈ ₹1,05,6xx; returns ~5.6%).
  final fdLate = FdItem(
    fixedDeposit(id: 10, institution: 'SBI', maturity: '2027-01-01'),
    today,
  );
  // FD maturing 15 Nov 2026 (₹50,000).
  final fdSoon = FdItem(
    fixedDeposit(
      id: 11,
      institution: 'Axis Bank',
      principal: 5000000,
      start: '2026-08-17',
      maturity: '2026-11-15',
    ),
    today,
  );
  final fdMatured = FdItem(
    fixedDeposit(
      id: 12,
      institution: 'ICICI',
      start: '2025-01-01',
      maturity: '2026-01-01',
    ),
    today,
  );
  final fdClosed = FdItem(
    fixedDeposit(
      id: 13,
      institution: 'Kotak',
      closure: FdClosure.withdrawn,
      closedOn: '2026-02-01',
      received: 10100000,
    ),
    today,
  );
  final all = <InvestmentItem>[
    unpriced,
    fdSoon,
    reliance,
    fdMatured,
    bees,
    fdClosed,
    abc,
    fdLate,
  ];

  List<String> names(InvestmentFilter f, InvestmentSort s) =>
      arrangeItems(all, filter: f, sort: s).items.map((i) => i.name).toList();

  test('current value, largest first; unpriced last', () {
    expect(names(InvestmentFilter.all, InvestmentSort.value), [
      'SBI', // ≈ 1,05,6xx
      'Axis Bank', // ≈ 50,7xx
      'Nippon Nifty BeES', // 25,957
      'Reliance Industries', // 12,090
      'Abc Ltd', // 3,000
      'Zed Co', // no price
    ]);
  });

  test('returns %, highest first', () {
    expect(names(InvestmentFilter.all, InvestmentSort.returns), [
      'Reliance Industries',
      'SBI',
      'Nippon Nifty BeES',
      'Axis Bank',
      'Abc Ltd',
      'Zed Co',
    ]);
  });

  test("today's change: market rows by %, FDs (no daily change) last", () {
    expect(names(InvestmentFilter.all, InvestmentSort.today), [
      'Reliance Industries',
      'Nippon Nifty BeES',
      'Abc Ltd',
      'Axis Bank', // then A–Z among rows without a change
      'SBI',
      'Zed Co',
    ]);
  });

  test('name A–Z', () {
    expect(names(InvestmentFilter.all, InvestmentSort.name), [
      'Abc Ltd',
      'Axis Bank',
      'Nippon Nifty BeES',
      'Reliance Industries',
      'SBI',
      'Zed Co',
    ]);
  });

  test('maturity date: only under FDs, where it is the default', () {
    expect(
      sortOptionsFor(InvestmentFilter.all),
      isNot(contains(InvestmentSort.maturity)),
    );
    expect(
      sortOptionsFor(InvestmentFilter.fds),
      contains(InvestmentSort.maturity),
    );
    expect(defaultSortFor(InvestmentFilter.fds), InvestmentSort.maturity);
    expect(defaultSortFor(InvestmentFilter.stocks), InvestmentSort.value);
    expect(
      effectiveSort(InvestmentSort.maturity, InvestmentFilter.all),
      InvestmentSort.value,
    );
    expect(
      effectiveSort(InvestmentSort.name, InvestmentFilter.fds),
      InvestmentSort.name,
    );
    expect(names(InvestmentFilter.fds, InvestmentSort.maturity), [
      'Axis Bank',
      'SBI',
    ]);
  });

  test('filters by asset class', () {
    expect(names(InvestmentFilter.stocks, InvestmentSort.name), [
      'Abc Ltd',
      'Reliance Industries',
      'Zed Co',
    ]);
    expect(names(InvestmentFilter.etfs, InvestmentSort.name), [
      'Nippon Nifty BeES',
    ]);
  });

  test('matured FDs pinned, closed FDs set apart (All and FDs only)', () {
    final arranged = arrangeItems(
      all,
      filter: InvestmentFilter.all,
      sort: InvestmentSort.value,
    );
    expect(arranged.pinned.map((i) => i.name), ['ICICI']);
    expect(arranged.closed.map((i) => i.name), ['Kotak']);
    expect(arranged.items.map((i) => i.name), isNot(contains('ICICI')));

    final stocks = arrangeItems(
      all,
      filter: InvestmentFilter.stocks,
      sort: InvestmentSort.value,
    );
    expect(stocks.pinned, isEmpty);
    expect(stocks.closed, isEmpty);
  });
}
