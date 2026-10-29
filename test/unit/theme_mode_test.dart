import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/state/theme_provider.dart';

void main() {
  group('ThemeModeNotifier & Persistence', () {
    late InMemoryStorageService storage;
    late ProviderContainer container;

    setUp(() {
      storage = InMemoryStorageService();
      container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to Dark mode when no preference is saved', () {
      final mode = container.read(themeModeProvider);
      expect(mode, ThemeMode.dark);
      expect(AppTheme.isDark, isTrue);
    });

    test(
      'switching to Light mode updates state, AppTheme.isDark, and persists',
      () async {
        await container
            .read(themeModeProvider.notifier)
            .setMode(ThemeMode.light);

        expect(container.read(themeModeProvider), ThemeMode.light);
        expect(AppTheme.isDark, isFalse);
        expect(storage.loadThemeMode(), 'light');
      },
    );

    test('toggle switches between Dark and Light mode', () async {
      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(AppTheme.isDark, isFalse);

      await container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(AppTheme.isDark, isTrue);
    });

    test(
      'restores previously saved theme mode across container restarts',
      () async {
        await container
            .read(themeModeProvider.notifier)
            .setMode(ThemeMode.light);
        container.dispose();

        final newContainer = ProviderContainer(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
        );

        expect(newContainer.read(themeModeProvider), ThemeMode.light);
        expect(AppTheme.isDark, isFalse);
        newContainer.dispose();
      },
    );
  });
}
