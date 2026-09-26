import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, tagalog, bisaya }

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  ThemeMode themeMode = ThemeMode.light;
  double fontScale = 1.0;
  AppLanguage language = AppLanguage.english;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = (prefs.getBool('dark_mode') ?? false) ? ThemeMode.dark : ThemeMode.light;
    fontScale = prefs.getDouble('font_scale') ?? 1.0;
    language = AppLanguage.values[prefs.getInt('language') ?? 0];
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('dark_mode', enabled);
  }

  Future<void> setFontScale(double scale) async {
    fontScale = scale;
    notifyListeners();
    (await SharedPreferences.getInstance()).setDouble('font_scale', scale);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    language = lang;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt('language', lang.index);
  }
}