import 'package:flutter/material.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/utils/holding_sort.dart';
import 'package:nse_price_spike/widgets/labels.dart';

/// All · Stocks · ETFs · FDs, showing only classes that are held.
class InvestmentFilterChips extends StatelessWidget {
  final List<InvestmentFilter> available;
  final InvestmentFilter selected;
  final ValueChanged<InvestmentFilter> onSelected;

  const InvestmentFilterChips({
    super.key,
    required this.available,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Wraps instead of scrolling sideways, so every chip is always visible
    // (at most four, even with large text on a 360 dp screen).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final f in available)
            ChoiceChip(
              key: Key('filter-${f.name}'),
              label: Text(filterLabel(f)),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              selected: f == selected,
              onSelected: (_) => onSelected(f),
            ),
        ],
      ),
    );
  }
}

/// The Total/Today toggle (stock and ETF rows only) and the sort menu.
class ListControls extends StatelessWidget {
  final bool showToday;
  final bool showToggle;
  final ValueChanged<bool> onShowTodayChanged;
  final InvestmentSort sort;
  final List<InvestmentSort> sortOptions;
  final ValueChanged<InvestmentSort> onSort;

  const ListControls({
    super.key,
    required this.showToday,
    required this.showToggle,
    required this.onShowTodayChanged,
    required this.sort,
    required this.sortOptions,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
      child: Row(
        children: [
          if (showToggle)
            SegmentedButton<bool>(
              key: const Key('totalTodayToggle'),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text(S.toggleTotal, key: Key('toggleTotal')),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(S.toggleToday, key: Key('toggleToday')),
                ),
              ],
              selected: {showToday},
              onSelectionChanged: (s) => onShowTodayChanged(s.first),
            ),
          const SizedBox(width: 8),
          // Takes the remaining width; the label truncates rather than
          // overflowing on narrow screens or with large text.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<InvestmentSort>(
                key: const Key('sortButton'),
                tooltip: S.sortTooltip,
                initialValue: sort,
                onSelected: onSort,
                itemBuilder: (context) => [
                  for (final s in sortOptions)
                    CheckedPopupMenuItem(
                      key: Key('sort-${s.name}'),
                      value: s,
                      checked: s == sort,
                      child: Text(sortLabel(s)),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          sortLabel(sort),
                          key: const Key('sortLabel'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Track your investments" with the two add buttons.
class InvestmentsEmptyState extends StatelessWidget {
  final VoidCallback onAddStock;
  final VoidCallback onAddFd;

  const InvestmentsEmptyState({
    super.key,
    required this.onAddStock,
    required this.onAddFd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            S.emptyTitle,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(S.emptyBody, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('emptyAddStock'),
            icon: const Icon(Icons.show_chart),
            label: const Text(S.addStockOrEtf),
            onPressed: onAddStock,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('emptyAddFd'),
            icon: const Icon(Icons.savings_outlined),
            label: const Text(S.addFd),
            onPressed: onAddFd,
          ),
        ],
      ),
    );
  }
}

enum AddChoice { stock, fd }

/// The "+ Add" bottom sheet: Stock or ETF / Fixed deposit.
Future<AddChoice?> showAddChoiceSheet(BuildContext context) =>
    showModalBottomSheet<AddChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                S.sheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              key: const Key('sheetStock'),
              leading: const Icon(Icons.show_chart),
              title: const Text(S.sheetStock),
              subtitle: const Text(S.sheetStockHint),
              onTap: () => Navigator.of(context).pop(AddChoice.stock),
            ),
            ListTile(
              key: const Key('sheetFd'),
              leading: const Icon(Icons.savings_outlined),
              title: const Text(S.sheetFd),
              subtitle: const Text(S.sheetFdHint),
              onTap: () => Navigator.of(context).pop(AddChoice.fd),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
