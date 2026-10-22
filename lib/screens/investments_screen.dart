import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/providers/investment_providers.dart';
import 'package:nse_price_spike/providers/refresh_providers.dart';
import 'package:nse_price_spike/providers/repository_providers.dart';
import 'package:nse_price_spike/screens/debug_screen.dart';
import 'package:nse_price_spike/screens/fd_actions.dart';
import 'package:nse_price_spike/screens/fd_detail_screen.dart';
import 'package:nse_price_spike/screens/fd_form_screen.dart';
import 'package:nse_price_spike/screens/holding_detail_screen.dart';
import 'package:nse_price_spike/screens/search_screen.dart';
import 'package:nse_price_spike/services/refresh_service.dart';
import 'package:nse_price_spike/utils/holding_sort.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';
import 'package:nse_price_spike/utils/trading_day.dart';
import 'package:nse_price_spike/widgets/common.dart';
import 'package:nse_price_spike/widgets/investment_controls.dart';
import 'package:nse_price_spike/widgets/investment_rows.dart';
import 'package:nse_price_spike/widgets/summary_card.dart';

/// Home: every investment (stocks, ETFs, FDs) with one summary.
class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  InvestmentFilter _filter = InvestmentFilter.all;

  /// The user's sort choice; null = the filter's default.
  InvestmentSort? _sort;
  bool _showToday = false;
  bool _closedExpanded = false;

  Future<void> _refresh() async {
    final outcome = await ref
        .read(refreshControllerProvider.notifier)
        .refresh();
    if (mounted && outcome is! RefreshFailed) {
      showSnack(context, outcome.message);
    }
  }

  void _push(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  void _addStock() => _push(const SearchScreen());

  void _addFd() => _push(const FdFormScreen());

  Future<void> _openAddSheet() async {
    final choice = await showAddChoiceSheet(context);
    switch (choice) {
      case AddChoice.stock:
        _addStock();
      case AddChoice.fd:
        _addFd();
      case null:
        break;
    }
  }

  Widget _row(InvestmentItem item) => switch (item) {
    MarketItem() => HoldingRow(
      key: Key('holdingRow-${item.holding.instrument.isin}'),
      item: item,
      showToday: _showToday,
      onTap: () =>
          _push(HoldingDetailScreen(instrumentId: item.holding.instrument.id)),
    ),
    FdItem() => FdRow(
      key: Key('fdRow-${item.fd.id}'),
      item: item,
      onTap: () => _push(FdDetailScreen(fdId: item.fd.id)),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(refreshControllerProvider.select((s) => s.busy));
    final settings = ref.watch(settingsProvider).valueOrNull;
    final summary = ref.watch(investmentsSummaryProvider);
    final items = ref.watch(investmentItemsProvider);
    final fileDate = settings?.lastFileTradeDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.investmentsTitle),
        actions: [
          IconButton(
            key: const Key('refreshButton'),
            tooltip: S.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: busy ? null : _refresh,
          ),
          IconButton(
            tooltip: S.debug,
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => _push(const DebugScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addButton'),
        icon: const Icon(Icons.add),
        label: const Text(S.add),
        onPressed: _openAddSheet,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            SizedBox(
              height: 4,
              child: busy ? const LinearProgressIndicator() : null,
            ),
            if (settings?.lastRefreshError != null)
              MaterialBanner(
                content: Text(S.couldntReach(pricesAsOf(fileDate))),
                leading: const Icon(Icons.cloud_off),
                actions: [
                  TextButton(
                    onPressed: busy ? null : _refresh,
                    child: const Text(S.retry),
                  ),
                ],
              ),
            ..._body(summary, items, fileDate),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    AsyncValue<InvestmentsSummary> summary,
    AsyncValue<List<InvestmentItem>> items,
    DateTime? fileDate,
  ) {
    if (items.hasError) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(S.loadFailed(items.error!)),
        ),
      ];
    }
    final s = summary.valueOrNull;
    final all = items.valueOrNull;
    if (s == null || all == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final hasClosed = all.any((i) => i is FdItem && i.fd.isClosed);
    if (s.isEmpty && !hasClosed) {
      return [InvestmentsEmptyState(onAddStock: _addStock, onAddFd: _addFd)];
    }

    // Chips only for held classes; fall back to All if a class empties.
    final held = s.heldClasses;
    final filters = [
      InvestmentFilter.all,
      for (final c in held) InvestmentFilter.of(c),
    ];
    final filter = filters.contains(_filter) ? _filter : InvestmentFilter.all;
    final sort = effectiveSort(_sort, filter);
    final arranged = arrangeItems(all, filter: filter, sort: sort);
    final showsMarket =
        filter != InvestmentFilter.fds &&
        (held.contains(AssetClass.stocks) || held.contains(AssetClass.etfs));

    return [
      SummaryCard(
        summary: s,
        marketDate: fileDate == null ? null : formatDisplayDate(fileDate),
        onInfo: () => showReturnsInfo(context),
      ),
      if (filters.length > 1)
        InvestmentFilterChips(
          available: filters,
          selected: filter,
          // A new filter starts from its default sort (Maturity date for
          // FDs, Current value elsewhere).
          onSelected: (f) => setState(() {
            _filter = f;
            _sort = null;
          }),
        ),
      ListControls(
        showToday: _showToday,
        showToggle: showsMarket,
        onShowTodayChanged: (v) => setState(() => _showToday = v),
        sort: sort,
        sortOptions: sortOptionsFor(filter),
        onSort: (v) => setState(() => _sort = v),
      ),
      for (final item in arranged.pinned)
        MaturedFdCard(
          key: Key('maturedPrompt-${item.fd.id}'),
          item: item,
          onTap: () => _push(FdDetailScreen(fdId: item.fd.id)),
          onWithdrawn: () => markFdWithdrawn(context, ref, item.fd),
          onRenewed: () => renewFd(context, item.fd),
        ),
      for (final item in arranged.items) _row(item),
      if (arranged.closed.isNotEmpty) ...[
        const Divider(height: 24),
        ListTile(
          key: const Key('closedSection'),
          title: Text(S.closedSection(arranged.closed.length)),
          trailing: Icon(
            _closedExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () => setState(() => _closedExpanded = !_closedExpanded),
        ),
        if (_closedExpanded)
          for (final item in arranged.closed)
            ClosedFdRow(
              key: Key('closedRow-${item.fd.id}'),
              item: item,
              onTap: () => _push(FdDetailScreen(fdId: item.fd.id)),
            ),
      ],
    ];
  }
}
