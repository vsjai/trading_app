import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'state/storage_providers.dart';

import 'ui/market/market_overview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = SharedPrefsStorageService();
  await storageService.init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const TradingApp(),
    ),
  );
}

class TradingApp extends StatelessWidget {
  const TradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trading App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MarketOverviewScreen(),
    );
  }
}
