import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'bp_screen.dart';
import 'album_list_screen.dart';
import 'add_medication_screen.dart';
import 'settings_screen.dart';
import 'stock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dateSubtitle = DateFormat('EEEE, MMMM d').format(now);

    final screens = [
      DashboardScreen(key: _dashboardKey),
      const CalendarScreen(),
      const BpScreen(),
      const AlbumListScreen(),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).textScaler.scale(68).clamp(68.0, 86.0)),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentIndex == 0
                            ? 'Today'
                            : _currentIndex == 1
                                ? 'Schedule'
                                : _currentIndex == 2
                                    ? 'Heart & BP'
                                    : 'Health Records',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        dateSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick shortcut for Medicine Kit & Stocks
                Tooltip(
                  message: 'Open Medicine Kit & Stocks',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StockScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 16,
                              color: isDark ? AppColors.primary : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Kit & Stocks',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Settings',
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSubtle : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                    _dashboardKey.currentState?.refresh();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: screens[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 56,
        width: 56,
        margin: const EdgeInsets.only(top: 24),
        child: FloatingActionButton(
          elevation: 3,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
            );
            if (result == true) {
              _dashboardKey.currentState?.refresh();
            }
          },
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          elevation: 0,
          color: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.calendar_today_rounded,
                  activeIcon: Icons.calendar_today_rounded,
                  label: 'Today',
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  isDark: isDark,
                ),
                const SizedBox(width: 48), // Spacer for center docked FAB
                _buildNavItem(
                  index: 2,
                  icon: Icons.favorite_outline_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: 'Vitals',
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  label: 'Records',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
