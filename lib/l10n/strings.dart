import '../services/app_settings.dart';

class AppStrings {
  static const Map<String, Map<AppLanguage, String>> _map = {
    'greeting': {AppLanguage.english: 'Hi there! 👋', AppLanguage.tagalog: 'Kumusta! 👋', AppLanguage.bisaya: 'Kumusta! 👋'},
    'todays_medicine': {AppLanguage.english: "Here's today's medicine", AppLanguage.tagalog: 'Narito ang gamot mo ngayon', AppLanguage.bisaya: 'Ania ang imong tambal karon'},
    'no_meds_today': {AppLanguage.english: 'No medications scheduled today.', AppLanguage.tagalog: 'Walang naka-iskedyul na gamot ngayon.', AppLanguage.bisaya: 'Walay iskedyul nga tambal karon.'},
    'settings': {AppLanguage.english: 'Settings', AppLanguage.tagalog: 'Mga Setting', AppLanguage.bisaya: 'Mga Setting'},
  };
  static String t(String key) => _map[key]?[AppSettings.instance.language] ?? key;
}