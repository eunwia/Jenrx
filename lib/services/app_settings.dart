import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, tagalog, bisaya }

enum AppTextSize { small, medium, large }

extension AppTextSizeX on AppTextSize {
  double get scaleFactor => switch (this) {
        AppTextSize.small => 0.88,
        AppTextSize.medium => 1.0,
        AppTextSize.large => 1.18,
      };

  String get label => switch (this) {
        AppTextSize.small => 'Small',
        AppTextSize.medium => 'Medium',
        AppTextSize.large => 'Large',
      };
}

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  ThemeMode themeMode = ThemeMode.light;
  AppTextSize textSize = AppTextSize.medium;
  AppLanguage language = AppLanguage.english;

  double get fontScale => textSize.scaleFactor;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = (prefs.getBool('dark_mode') ?? false) ? ThemeMode.dark : ThemeMode.light;

    // Migrate or load text size setting
    final savedTextSize = prefs.getString('text_size');
    if (savedTextSize != null) {
      textSize = AppTextSize.values.firstWhere(
        (e) => e.name == savedTextSize,
        orElse: () => AppTextSize.medium,
      );
    } else {
      // Legacy font_scale migration
      final legacyScale = prefs.getDouble('font_scale');
      if (legacyScale != null) {
        if (legacyScale < 0.95) {
          textSize = AppTextSize.small;
        } else if (legacyScale >= 1.10) {
          textSize = AppTextSize.large;
        } else {
          textSize = AppTextSize.medium;
        }
      } else {
        textSize = AppTextSize.medium;
      }
    }

    language = AppLanguage.values[prefs.getInt('language') ?? 0];
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
  }

  Future<void> setTextSize(AppTextSize size) async {
    textSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('text_size', size.name);
    await prefs.setDouble('font_scale', fontScale);
  }

  // Deprecated helper to preserve any legacy callers if any
  Future<void> setFontScale(double scale) async {
    if (scale < 0.95) {
      await setTextSize(AppTextSize.small);
    } else if (scale >= 1.10) {
      await setTextSize(AppTextSize.large);
    } else {
      await setTextSize(AppTextSize.medium);
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('language', lang.index);
  }
}
