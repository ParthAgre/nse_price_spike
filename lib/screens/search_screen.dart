import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/providers/refresh_providers.dart';
import 'package:nse_price_spike/screens/holding_form_screen.dart';

/// Fully local search: no network per keystroke.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(symbolSearchIndexProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('searchField'),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: S.searchHint,
            border: InputBorder.none,
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(S.searchLoadFailed(e))),
        data: (index) {
          if (index.length == 0) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(S.searchNoList),
            );
          }
          if (_query.trim().isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(S.searchPrompt(index.length)),
            );
          }
          final results = index.search(_query);
          if (results.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(S.searchNoMatches),
            );
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, i) {
              final entry = results[i];
              return ListTile(
                title: Text(entry.symbol),
                subtitle: Text(
                  '${entry.name}\n${entry.isin}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: Text(entry.type.label),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HoldingFormScreen(instrument: entry),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
