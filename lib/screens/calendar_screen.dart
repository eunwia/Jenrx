import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../db/database_helper.dart';
import '../models/med_log.dart';
import '../theme/app_theme.dart';
import '../utils/med_icons.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_bottom_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, String> _compliance = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonth(_focusedDay);
  }

  Future<void> _loadMonth(DateTime day) async {
    final data = await DatabaseHelper.instance
        .getComplianceForMonth(day.year, day.month);
    if (!mounted) return;
    setState(() => _compliance = data);
  }

  Color? _dotColor(DateTime day) {
    final key = DatabaseHelper.instance.formatDate(day);
    switch (_compliance[key]) {
      case 'green':
        return AppColors.success;
      case 'yellow':
        return AppColors.warning;
      case 'red':
        return AppColors.danger;
      default:
        return null;
    }
  }

  Future<void> _showDayDetail(DateTime day) async {
    final dateStr = DatabaseHelper.instance.formatDate(day);
    final meds = await DatabaseHelper.instance.getActiveMedications();
    final medById = {for (var m in meds) m.id: m};
    List<MedLog> logs = await DatabaseHelper.instance.getLogsForDate(dateStr);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (modalContext, setSheetState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;
          final takenCount = logs.where((l) => l.isTaken).length;

          return CustomBottomSheet(
            title: formatDateReadable(dateStr),
            subtitle: logs.isEmpty
                ? 'No medications logged'
                : '$takenCount of ${logs.length} taken',
            child: logs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 48,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No dose entries for this day.',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: logs.map((log) {
                      final med = medById[log.medicationId];
                      final taken = log.isTaken;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: taken
                              ? (isDark ? AppColors.successDark.withValues(alpha: 0.3) : AppColors.successLight)
                              : (isDark ? AppColors.dangerDark.withValues(alpha: 0.3) : AppColors.dangerLight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: taken
                                ? AppColors.success.withValues(alpha: 0.25)
                                : AppColors.danger.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (taken ? AppColors.success : AppColors.danger)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                taken ? Icons.check_rounded : Icons.close_rounded,
                                color: taken ? AppColors.success : AppColors.danger,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med?.name ?? 'Unknown Medication',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    formatTime12(log.scheduledTime) +
                                        (taken && log.takenAt != null && log.takenAt!.length >= 16
                                            ? ' • Taken at ${formatTime12(log.takenAt!.substring(11, 16))}'
                                            : (taken ? ' • Taken' : ' • Missed')),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: modalContext,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text('Delete Entry?'),
                                    content: const Text('Are you sure you want to delete this log entry?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogCtx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(dialogCtx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await DatabaseHelper.instance.deleteLog(log.id!);
                                  final refreshed = await DatabaseHelper.instance.getLogsForDate(dateStr);
                                  setSheetState(() => logs = refreshed);
                                  _loadMonth(_focusedDay);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final perfectDays = _compliance.values.where((v) => v == 'green').length;
    final partialDays = _compliance.values.where((v) => v == 'yellow').length;
    final missedDays = _compliance.values.where((v) => v == 'red').length;
    final totalLoggedDays = perfectDays + partialDays + missedDays;
    final adherencePct = totalLoggedDays > 0 ? ((perfectDays / totalLoggedDays) * 100).round() : 100;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        // Adherence Overview Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MONTHLY ADHERENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  StatusBadge(
                    label: '$adherencePct% Adherence',
                    variant: adherencePct >= 80 ? BadgeVariant.success : BadgeVariant.warning,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$perfectDays perfect ${perfectDays == 1 ? 'day' : 'days'} this month',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap any day to review dosage history & logs',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // Legend row
              Row(
                children: [
                  _buildLegendItem(AppColors.success, 'Perfect ($perfectDays)', isDark),
                  const SizedBox(width: 14),
                  _buildLegendItem(AppColors.warning, 'Partial ($partialDays)', isDark),
                  const SizedBox(width: 14),
                  _buildLegendItem(AppColors.danger, 'Missed ($missedDays)', isDark),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // TableCalendar Card
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: TableCalendar(
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              weekendStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              defaultTextStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              weekendTextStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              outsideDaysVisible: false,
            ),
            onPageChanged: (day) {
              _focusedDay = day;
              _loadMonth(day);
            },
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _showDayDetail(selected);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final color = _dotColor(day);
                if (color == null) return null;
                return Container(
                  margin: const EdgeInsets.only(top: 26),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
