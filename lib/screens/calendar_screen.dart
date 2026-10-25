import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../db/database_helper.dart';
import '../models/med_log.dart';
import '../models/appointment.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/med_icons.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/empty_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 0: Medication Calendar, 1: Hospital Appointments
  int _activeTab = 0;

  // Medication Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, String> _compliance = {};

  // Hospital Appointments State
  DateTime _apptFocusedDay = DateTime.now();
  DateTime? _apptSelectedDay;
  List<Appointment> _allAppointments = [];
  Set<String> _appointmentDates = {};
  bool _loadingAppts = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _apptSelectedDay = _apptFocusedDay;
    _loadMedMonth(_focusedDay);
    _loadAppointments();
  }

  Future<void> _loadMedMonth(DateTime day) async {
    final data = await DatabaseHelper.instance
        .getComplianceForMonth(day.year, day.month);
    if (!mounted) return;
    setState(() => _compliance = data);
  }

  Future<void> _loadAppointments() async {
    final db = DatabaseHelper.instance;
    final list = await db.getAllAppointments();
    final dates = await db.getAppointmentDatesForMonth(
        _apptFocusedDay.year, _apptFocusedDay.month);
    if (!mounted) return;
    setState(() {
      _allAppointments = list;
      _appointmentDates = dates;
      _loadingAppts = false;
    });
  }

  Color? _medDotColor(DateTime day) {
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

  // --- Medication Day Details ---

  Future<void> _showMedDayDetail(DateTime day) async {
    final dateStr = DatabaseHelper.instance.formatDate(day);
    final meds = await DatabaseHelper.instance.getActiveMedications();
    final medById = {for (var m in meds) m.id: m};
    List<MedLog> logs = await DatabaseHelper.instance.getLogsForDate(dateStr);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                  _loadMedMonth(_focusedDay);
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

  // --- Hospital Appointments CRUD ---

  Future<void> _openAppointmentForm({Appointment? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final hospitalCtrl = TextEditingController(text: existing?.hospital ?? '');
    final doctorCtrl = TextEditingController(text: existing?.doctor ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    String selectedDate = existing?.date ?? DatabaseHelper.instance.formatDate(DateTime.now());
    String selectedTime = existing?.time ?? '09:00';
    int reminderMinutes = existing?.reminderMinutes ?? 60;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (modalContext, setSheetState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;

          return CustomBottomSheet(
            title: existing != null ? 'Edit Appointment' : 'New Hospital Appointment',
            subtitle: 'Schedule consultations, laboratory tests, or checkups',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Appointment Title / Reason *',
                    hintText: 'e.g. Cardiologist Checkup, Routine Blood Test',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalCtrl,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Hospital or Clinic Name *',
                    hintText: 'e.g. City General Hospital, St. Luke’s',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doctorCtrl,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Doctor / Specialist Name (optional)',
                    hintText: 'e.g. Dr. Emily Santos (Cardiologist)',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                // Date & Time pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final current = DateTime.tryParse(selectedDate) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: modalContext,
                            initialDate: current,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            setSheetState(() {
                              selectedDate = DatabaseHelper.instance.formatDate(picked);
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.grey[600])),
                                    Text(
                                      selectedDate,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final parts = selectedTime.split(':');
                          final initialTime = TimeOfDay(
                            hour: int.tryParse(parts[0]) ?? 9,
                            minute: int.tryParse(parts[1]) ?? 0,
                          );
                          final picked = await showTimePicker(
                            context: modalContext,
                            initialTime: initialTime,
                          );
                          if (picked != null) {
                            setSheetState(() {
                              selectedTime =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Time', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.grey[600])),
                                    Text(
                                      formatTime12(selectedTime),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: locationCtrl,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Location / Room / Building (optional)',
                    hintText: 'e.g. Bldg B, 3rd Floor, Room 302',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Notes & Preparation Instructions (optional)',
                    hintText: 'e.g. Bring previous lab results, 8 hours fasting',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // Reminder selector
                DropdownButtonFormField<int>(
                  initialValue: reminderMinutes,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Appointment Reminder',
                    prefixIcon: Icon(Icons.notifications_active_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('No reminder')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                    DropdownMenuItem(value: 60, child: Text('1 hour before')),
                    DropdownMenuItem(value: 120, child: Text('2 hours before')),
                    DropdownMenuItem(value: 1440, child: Text('1 day before')),
                  ],
                  onChanged: (v) => setSheetState(() => reminderMinutes = v ?? 60),
                ),
                const SizedBox(height: 20),

                // Action buttons: Cancel & Save
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          final hospital = hospitalCtrl.text.trim();
                          if (title.isEmpty || hospital.isEmpty) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              SnackBar(
                                content: const Text('Please enter an appointment title and hospital name.'),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            return;
                          }

                          final appt = Appointment(
                            id: existing?.id,
                            title: title,
                            hospital: hospital,
                            doctor: doctorCtrl.text.trim().isEmpty ? null : doctorCtrl.text.trim(),
                            date: selectedDate,
                            time: selectedTime,
                            location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            reminderMinutes: reminderMinutes,
                          );

                          final db = DatabaseHelper.instance;
                          if (existing != null) {
                            await NotificationService.cancelForAppointment(existing.id!);
                            await db.updateAppointment(appt);
                            await NotificationService.scheduleForAppointment(appt);
                          } else {
                            final id = await db.insertAppointment(appt);
                            await NotificationService.scheduleForAppointment(appt.copyWith(id: id));
                          }

                          if (bottomSheetContext.mounted) {
                            Navigator.pop(bottomSheetContext);
                          }
                          _loadAppointments();
                        },
                        child: Text(
                          existing != null ? 'Save Changes' : 'Save Appointment',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),

                if (existing != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: modalContext,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Delete Appointment?'),
                            content: Text('Remove appointment for "${existing.title}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await NotificationService.cancelForAppointment(existing.id!);
                          await DatabaseHelper.instance.deleteAppointment(existing.id!);
                          if (bottomSheetContext.mounted) {
                            Navigator.pop(bottomSheetContext);
                          }
                          _loadAppointments();
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete Appointment'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        // Two-Tab Segmented Selector
        _buildSegmentedTabSelector(isDark),

        const SizedBox(height: 14),

        if (_activeTab == 0)
          _buildMedicationCalendarView(isDark)
        else
          _buildHospitalAppointmentsView(isDark),
      ],
    );
  }

  Widget _buildSegmentedTabSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFE5E9F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabPill(
              title: 'Medication Calendar',
              icon: Icons.medication_outlined,
              isSelected: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabPill(
              title: 'Hospital Appointments',
              icon: Icons.local_hospital_outlined,
              isSelected: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW A: Medication Calendar
  // ==========================================

  Widget _buildMedicationCalendarView(bool isDark) {
    final perfectDays = _compliance.values.where((v) => v == 'green').length;
    final partialDays = _compliance.values.where((v) => v == 'yellow').length;
    final missedDays = _compliance.values.where((v) => v == 'red').length;
    final totalLoggedDays = perfectDays + partialDays + missedDays;
    final adherencePct = totalLoggedDays > 0 ? ((perfectDays / totalLoggedDays) * 100).round() : 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'MEDICATION ADHERENCE',
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
              // Legend row with Wrap to avoid overflow
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _buildLegendItem(AppColors.success, 'Perfect ($perfectDays)', isDark),
                  _buildLegendItem(AppColors.warning, 'Partial ($partialDays)', isDark),
                  _buildLegendItem(AppColors.danger, 'Missed ($missedDays)', isDark),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // TableCalendar Card for Medication
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
              _loadMedMonth(day);
            },
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _showMedDayDetail(selected);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final color = _medDotColor(day);
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

  // ==========================================
  // VIEW B: Hospital Appointments Calendar
  // ==========================================

  Widget _buildHospitalAppointmentsView(bool isDark) {
    if (_loadingAppts) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter appointments for selected day (if any) or all upcoming
    final selectedDayStr = _apptSelectedDay != null
        ? DatabaseHelper.instance.formatDate(_apptSelectedDay!)
        : null;

    final displayedAppointments = selectedDayStr != null
        ? _allAppointments.where((a) => a.date == selectedDayStr).toList()
        : _allAppointments;

    final upcomingCount = _allAppointments
        .where((a) => a.date.compareTo(DatabaseHelper.instance.formatDate(DateTime.now())) >= 0)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hospital Appointments Summary Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'HOSPITAL APPOINTMENTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: '$upcomingCount Upcoming',
                    variant: upcomingCount > 0 ? BadgeVariant.info : BadgeVariant.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                upcomingCount > 0
                    ? '$upcomingCount medical ${upcomingCount == 1 ? 'visit' : 'visits'} scheduled'
                    : 'No upcoming hospital appointments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track doctor checkups, laboratory dates, and clinic visits',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _openAppointmentForm(),
                  icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  label: const Text('Schedule New Appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Hospital Appointments Calendar Card
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: TableCalendar(
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _apptFocusedDay,
            selectedDayPredicate: (day) => isSameDay(_apptSelectedDay, day),
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
                color: AppColors.info.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.info,
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
              _apptFocusedDay = day;
              _loadAppointments();
            },
            onDaySelected: (selected, focused) {
              setState(() {
                if (isSameDay(_apptSelectedDay, selected)) {
                  // Toggle off filter if clicked twice
                  _apptSelectedDay = null;
                } else {
                  _apptSelectedDay = selected;
                }
                _apptFocusedDay = focused;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final dateStr = DatabaseHelper.instance.formatDate(day);
                if (!_appointmentDates.contains(dateStr)) return null;
                return Container(
                  margin: const EdgeInsets.only(top: 26),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.info,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDayStr != null
                  ? 'APPOINTMENTS ON ${DateFormat('MMM d, yyyy').format(_apptSelectedDay!)}'
                  : 'ALL SCHEDULED APPOINTMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            if (selectedDayStr != null)
              GestureDetector(
                onTap: () => setState(() => _apptSelectedDay = null),
                child: const Text(
                  'Show All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Appointments List
        if (displayedAppointments.isEmpty) ...[
          EmptyStateView(
            icon: Icons.local_hospital_outlined,
            title: selectedDayStr != null ? 'No Visits on This Date' : 'No Hospital Appointments',
            description: selectedDayStr != null
                ? 'No medical appointments scheduled for this selected day.'
                : 'Keep all your hospital dates, lab tests, and doctor checkups organized.',
            actionLabel: 'Schedule Appointment',
            onAction: () => _openAppointmentForm(),
          ),
        ] else ...[
          ...displayedAppointments.map((appt) => _buildAppointmentCard(appt, isDark)),
        ],
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appt, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => _openAppointmentForm(existing: appt),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_hospital_rounded, color: AppColors.info, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          appt.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: formatTime12(appt.time),
                        variant: BadgeVariant.info,
                        fontSize: 11,
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.business_rounded, size: 13, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appt.hospital + (appt.doctor != null && appt.doctor!.isNotEmpty ? ' • ${appt.doctor}' : ''),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_rounded, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            formatDateReadable(appt.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                      if (appt.reminderMinutes > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.alarm_on_rounded, size: 13, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(
                              '${appt.reminderMinutes >= 1440 ? '1d' : '${appt.reminderMinutes}m'} reminder',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (appt.location != null && appt.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.place_outlined, size: 13, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appt.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Prep: ${appt.notes}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
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
