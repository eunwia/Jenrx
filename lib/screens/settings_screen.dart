import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../l10n/strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Text Size', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Slider(
            value: settings.fontScale, min: 0.85, max: 1.6, divisions: 6,
            label: '${(settings.fontScale * 100).round()}%',
            onChanged: (v) => setState(() => settings.setFontScale(v)),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Dark Mode', style: TextStyle(fontSize: 18)),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (v) => setState(() => settings.setDarkMode(v)),
          ),
          const SizedBox(height: 20),
          const Text('Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ...AppLanguage.values.map((lang) => RadioListTile<AppLanguage>(
                title: Text(_label(lang), style: const TextStyle(fontSize: 18)),
                value: lang, groupValue: settings.language,
                onChanged: (v) => setState(() => settings.setLanguage(v!)),
              )),
        ],
      ),
    );
  }

  String _label(AppLanguage l) => switch (l) {
        AppLanguage.english => 'English',
        AppLanguage.tagalog => 'Tagalog',
        AppLanguage.bisaya => 'Bisaya',
      };
}