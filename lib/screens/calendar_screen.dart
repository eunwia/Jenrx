import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../db/database_helper.dart';
import '../models/med_log.dart';
import '../utils/med_icons.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  Map<String, String> _compliance = {};

  static const _blue = Color(0xFF1565F5);

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
  }

  Future<void> _loadMonth(DateTime day) async {
    final data = await DatabaseHelper.instance
        .getComplianceForMonth(day.year, day.month);
    setState(() => _compliance = data);
  }

  Color? _dotColor(DateTime day) {
    final key = DatabaseHelper.instance.formatDate(day);
    switch (_compliance[key]) {
      case 'green': return Colors.green;
      case 'yellow': return Colors.orange;
      case 'red': return Colors.red;
      default: return null;
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatDateReadable(dateStr),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No entries for this day.', style: TextStyle(fontSize: 16))),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: logs.map((log) {
                      final med = medById[log.medicationId];
                      final taken = log.isTaken;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: taken ? const Color(0xFFEAF7ED) : const Color(0xFFFBEAEA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(taken ? Icons.check_circle : Icons.cancel,
                                color: taken ? Colors.green : Colors.red, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med?.name ?? 'Unknown',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Text(
                                    formatTime12(log.scheduledTime) +
                                        (taken
                                            ? ' • taken at ${formatTime12(log.takenAt!.substring(11, 16))}'
                                            : ' • missed'),
                                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete this entry?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Image.asset('assets/images/jen_calendar.png', height: 140),
          ),
          const SizedBox(height: 12),
          const Text(
            'Track your medicine intake',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime(2030, 12, 31),
              focusedDay: _focusedDay,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: _blue.withOpacity(0.15), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: _blue, fontWeight: FontWeight.bold),
                selectedDecoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                defaultTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
                weekendTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              onPageChanged: (day) {
                _focusedDay = day;
                _loadMonth(day);
              },
              onDaySelected: (selected, focused) => _showDayDetail(selected),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final color = _dotColor(day);
                  if (color == null) return null;
                  return Container(
                    margin: const EdgeInsets.only(top: 30),
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}