import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import 'add_medication_screen.dart';

class ManageMedicationsScreen extends StatefulWidget {
  const ManageMedicationsScreen({super.key});
  @override
  State<ManageMedicationsScreen> createState() => _ManageMedicationsScreenState();
}

class _ManageMedicationsScreenState extends State<ManageMedicationsScreen> {
  List<Medication> _meds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meds = await DatabaseHelper.instance.getActiveMedications();
    setState(() => _meds = meds);
  }

  Future<void> _archive(Medication med) async {
    await NotificationService.cancelForMedication(med);
    await DatabaseHelper.instance.archiveMedication(med.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Medications')),
      body: _meds.isEmpty
          ? const Center(child: Text('No medications yet.', style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _meds.length,
              itemBuilder: (context, i) {
                final med = _meds[i];
                return Dismissible(
                  key: ValueKey(med.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove medication?'),
                      content: Text('Past history for ${med.name} will be kept.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
                      ],
                    ),
                  ),
                  onDismissed: (_) => _archive(med),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(med.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      subtitle: Text('${med.dosage} • ${med.timeList.join(', ')}'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final result = await Navigator.push(context,
                            MaterialPageRoute(builder: (context) => AddMedicationScreen(existing: med)));
                        if (result == true) _load();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}