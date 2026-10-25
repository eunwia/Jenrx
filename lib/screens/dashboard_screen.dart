import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../models/med_log.dart';
import '../theme/app_theme.dart';
import '../utils/album_colors.dart';
import '../utils/med_icons.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';
import 'add_medication_screen.dart';
import 'stock_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _filter = 'all'; // 'all', 'pending', 'taken'
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final db = DatabaseHelper.instance;
    await db.ensureLogsForToday();
    final today = db.formatDate(DateTime.now());
    final meds = await db.getActiveMedications();
    final logs = await db.getLogsForDate(today);
    final medById = {for (var m in meds) m.id: m};

    final items = logs
        .where((log) => medById.containsKey(log.medicationId))
        .map((log) => {'log': log, 'med': medById[log.medicationId]!})
        .toList();

    items.sort((a, b) => (a['log'] as MedLog)
        .scheduledTime
        .compareTo((b['log'] as MedLog).scheduledTime));

    // Check low stocks
    int lowCount = 0;
    try {
      final stockList = await db.getStock();
      for (final s in stockList) {
        final medId = s['medication_id'];
        if (medId != null && medById.containsKey(medId)) {
          final med = medById[medId]!;
          if (med.timeList.isNotEmpty) {
            final bought = DateTime.parse(s['date_bought']);
            final daysLeft = (s['quantity'] as int) / med.timeList.length;
            final runOut = bought.add(Duration(days: daysLeft.floor()));
            if (runOut.difference(DateTime.now()).inDays <= 5) {
              lowCount++;
            }
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _items = items;
      _lowStockCount = lowCount;
      _loading = false;
    });
  }

  Future<void> _toggleTaken(MedLog log) async {
    HapticFeedback.lightImpact();
    final db = DatabaseHelper.instance;
    if (log.isTaken) {
      await db.undoTaken(log.id!);
    } else {
      await db.markTaken(log.id!, DateTime.now().toIso8601String());
    }
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_items.isEmpty) {
      return EmptyStateView(
        imageAsset: 'assets/images/no_meds_illus.png',
        title: 'No Medications Today',
        description: 'You have no scheduled doses for today. Stay hydrated and have a wonderful day!',
        actionLabel: 'Add Medication',
        onAction: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
          );
          if (result == true) refresh();
        },
      );
    }

    final totalDoses = _items.length;
    final takenDoses = _items.where((i) => (i['log'] as MedLog).isTaken).length;
    final pendingDoses = totalDoses - takenDoses;
    final progress = totalDoses > 0 ? (takenDoses / totalDoses) : 0.0;

    final filteredItems = _items.where((i) {
      final isTaken = (i['log'] as MedLog).isTaken;
      if (_filter == 'pending') return !isTaken;
      if (_filter == 'taken') return isTaken;
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: refresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          // Adherence Summary Card
          _buildSummaryCard(progress, takenDoses, totalDoses, isDark),

          // Low Stock Alert Banner (if any)
          if (_lowStockCount > 0) ...[
            const SizedBox(height: 12),
            _buildLowStockBanner(isDark),
          ],

          const SizedBox(height: 16),

          // Filter Segmented Pills
          _buildFilterRow(totalDoses, pendingDoses, takenDoses, isDark),

          const SizedBox(height: 14),

          // Medications List
          if (filteredItems.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  _filter == 'pending'
                      ? '🎉 All pending doses completed!'
                      : 'No doses taken yet today.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ] else ...[
            ...filteredItems.map((item) {
              final MedLog log = item['log'];
              final Medication med = item['med'];
              return _buildMedicationCard(log, med, isDark);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double progress, int taken, int total, bool isDark) {
    final pct = (progress * 100).round();
    final allDone = total > 0 && taken == total;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'DAILY ADHERENCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (allDone)
                          const StatusBadge(
                            label: 'Completed',
                            variant: BadgeVariant.success,
                            fontSize: 11,
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$taken of $total doses taken',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (allDone ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: allDone ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFE9ECEF),
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockBanner(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StockScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.warningDark : AppColors.warningLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_lowStockCount medication${_lowStockCount > 1 ? 's' : ''} running low',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Tap to check your Medicine Kit stocks',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF7A4A00),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.warning, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(int total, int pending, int taken, bool isDark) {
    return Row(
      children: [
        _buildFilterChip('all', 'All ($total)', isDark),
        const SizedBox(width: 8),
        _buildFilterChip('pending', 'Pending ($pending)', isDark),
        const SizedBox(width: 8),
        _buildFilterChip('taken', 'Taken ($taken)', isDark),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSelected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : AppColors.lightTextPrimary)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationCard(MedLog log, Medication med, bool isDark) {
    final taken = log.isTaken;
    final medColor = colorFromHex(med.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: taken
            ? (isDark
                ? AppColors.successDark.withValues(alpha: 0.3)
                : AppColors.successLight.withValues(alpha: 0.5))
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Medicine Icon Container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: medColor.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: medColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                iconForKey(med.icon),
                color: medColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Med Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          med.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            decoration: taken ? TextDecoration.lineThrough : null,
                            decorationColor: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (med.purpose.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: medColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            med.purpose,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: medColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (med.dosage.isNotEmpty) ...[
                        Text(
                          med.dosage,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        formatTime12(log.scheduledTime),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (taken && log.takenAt != null && log.takenAt!.length >= 16) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Taken at ${formatTime12(log.takenAt!.substring(11, 16))}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Edit button
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              tooltip: 'Edit Medication',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddMedicationScreen(existing: med)),
                );
                if (result == true) refresh();
              },
            ),

            // Check / Toggle Taken Button
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _toggleTaken(log),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: taken ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: taken
                        ? AppColors.success
                        : (isDark ? AppColors.darkBorder : AppColors.primary),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      taken ? Icons.check_rounded : Icons.check_rounded,
                      size: 16,
                      color: taken
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      taken ? 'Taken' : 'Take',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: taken
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
