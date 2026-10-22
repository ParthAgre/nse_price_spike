import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/providers/investment_providers.dart';
import 'package:nse_price_spike/providers/refresh_providers.dart';
import 'package:nse_price_spike/screens/investments_screen.dart';
import 'package:nse_price_spike/theme/app_theme.dart';

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
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _onResume() {
    // A new day changes FD values and statuses.
    ref.invalidate(todayProvider);
    _refresh();
  }

  void _refresh() {
    ref.read(refreshControllerProvider.notifier).refresh(automatic: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appTitle,
      theme: buildAppTheme(),
      home: const InvestmentsScreen(),
    );
  }
}
