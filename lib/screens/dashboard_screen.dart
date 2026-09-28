import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../models/med_log.dart';
import '../utils/album_colors.dart';
import '../utils/med_icons.dart';
import 'add_medication_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

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
    setState(() { _items = items; _loading = false; });
  }

  Future<void> _toggleTaken(MedLog log) async {
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/no_meds_illus.png', width: 200),
            const SizedBox(height: 16),
            const Text('No medications scheduled today.',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final MedLog log = _items[index]['log'];
        final Medication med = _items[index]['med'];
        final taken = log.isTaken;
        final medColor = colorFromHex(med.color);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = taken
            ? (isDark ? const Color(0xFF1B3A25) : const Color(0xFFEAF7ED))
            : Theme.of(context).cardColor;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: medColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconForKey(med.icon), color: medColor, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (med.purpose.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: medColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(med.purpose,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: medColor)),
                      ),
                    Text(med.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 6),
                    if (med.dosage.isNotEmpty)
                      Text('Dosage: ${med.dosage}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    if (med.dosage.isNotEmpty) const SizedBox(height: 2),
                    Text('Time: ${formatTime12(log.scheduledTime)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AddMedicationScreen(existing: med)));
                  if (result == true) refresh();
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                  child: const Icon(Icons.edit, size: 20, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleTaken(log),
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: taken ? Colors.green : medColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    taken ? Icons.check : Icons.check_outlined,
                    color: Colors.white, size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}