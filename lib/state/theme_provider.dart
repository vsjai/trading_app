import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../services/storage_service.dart';
import 'storage_providers.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(_loadInitial(_storage));

  static ThemeMode _loadInitial(StorageService storage) {
    final saved = storage.loadThemeMode();
    if (saved == 'light') {
      AppTheme.isDark = false;
      return ThemeMode.light;
    }
    AppTheme.isDark = true;
    return ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    AppTheme.isDark = (mode != ThemeMode.light);
    await _storage.saveThemeMode(mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setMode(next);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});
