import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/providers/refresh_providers.dart';
import 'package:nse_price_spike/screens/portfolio_screen.dart';

void main() {
  runApp(const ProviderScope(child: NsePriceSpikeApp()));
}

class NsePriceSpikeApp extends ConsumerStatefulWidget {
  const NsePriceSpikeApp({super.key});

  @override
  ConsumerState<NsePriceSpikeApp> createState() => _NsePriceSpikeAppState();
}

class _NsePriceSpikeAppState extends ConsumerState<NsePriceSpikeApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Refresh on open and on every resume; runs in the background.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    ref.read(refreshControllerProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NSE Price Spike',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const PortfolioScreen(),
    );
  }
}
