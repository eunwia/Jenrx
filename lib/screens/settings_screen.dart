import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'manage_medications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Section 1: Appearance
          _buildSectionTitle('APPEARANCE', isDark),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dark_mode_outlined, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Dark Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Calming dark palette for night viewing', style: TextStyle(fontSize: 12)),
                  value: settings.themeMode == ThemeMode.dark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => settings.setDarkMode(v)),
                ),
                Divider(
                  height: 1,
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.8),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.format_size_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('Text Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(settings.fontScale * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: settings.fontScale,
                        min: 0.85,
                        max: 1.6,
                        divisions: 5,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => settings.setFontScale(v)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('A', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey[600])),
                          Text('Default', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey[600])),
                          Text('A', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.grey : Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Medication Library
          _buildSectionTitle('MEDICATION MANAGEMENT', isDark),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_information_outlined, color: AppColors.success, size: 20),
              ),
              title: const Text('Manage Medications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: const Text('View active list, edit schedules or archive', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageMedicationsScreen()),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Language
          _buildSectionTitle('LANGUAGE & LOCALIZATION', isDark),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: AppLanguage.values.map((lang) {
                final isSelected = settings.language == lang;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    _label(lang),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                      : null,
                  onTap: () => setState(() => settings.setLanguage(lang)),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Section 4: Privacy & Information
          _buildSectionTitle('ABOUT & DATA PRIVACY', isDark),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.info, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Offline & Private',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'All health records stay securely on your device',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.8),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'JCares Med Tracker',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      'v1.0.0+1',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  String _label(AppLanguage l) => switch (l) {
        AppLanguage.english => 'English',
        AppLanguage.tagalog => 'Tagalog (Filipino)',
        AppLanguage.bisaya => 'Bisaya (Cebuano)',
      };
}
