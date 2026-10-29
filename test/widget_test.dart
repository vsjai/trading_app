import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/main.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/storage_providers.dart';

void main() {
  testWidgets('TradingApp smoke test boots cleanly with ProviderScope', (
    WidgetTester tester,
  ) async {
    final inMemoryStorage = InMemoryStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(inMemoryStorage)],
        child: const TradingApp(),
      ),
    );

    expect(find.text('Live Market'), findsOneWidget);
  });
}
