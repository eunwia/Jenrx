import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/album_colors.dart';
import '../utils/med_icons.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import 'add_medication_screen.dart';

class ManageMedicationsScreen extends StatefulWidget {
  const ManageMedicationsScreen({super.key});

  @override
  State<ManageMedicationsScreen> createState() => _ManageMedicationsScreenState();
}

class _ManageMedicationsScreenState extends State<ManageMedicationsScreen> {
  List<Medication> _meds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meds = await DatabaseHelper.instance.getActiveMedications();
    if (!mounted) return;
    setState(() {
      _meds = meds;
      _loading = false;
    });
  }

  Future<void> _archive(Medication med) async {
    await NotificationService.cancelForMedication(med);
    await DatabaseHelper.instance.archiveMedication(med.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Medications'),
        actions: [
          IconButton(
            tooltip: 'Add Medication',
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
              );
              if (result == true) _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _meds.isEmpty
              ? EmptyStateView(
                  icon: Icons.medication_outlined,
                  title: 'No Active Medications',
                  description: 'Add medications to track dosages, frequencies, and get scheduled reminders.',
                  actionLabel: 'Add Medication',
                  onAction: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
                    );
                    if (result == true) _load();
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: _meds.length,
                  itemBuilder: (context, i) {
                    final med = _meds[i];
                    final medColor = colorFromHex(med.color);

                    return Dismissible(
                      key: ValueKey(med.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Archive',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.archive_outlined, color: Colors.white),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Archive Medication?'),
                          content: Text('Remove ${med.name}? All historical logs will be preserved safely.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Archive'),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) => _archive(med),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddMedicationScreen(existing: med)),
                            );
                            if (result == true) _load();
                          },
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: medColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(iconForKey(med.icon), color: medColor, size: 24),
                              ),
                              const SizedBox(width: 14),
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                                    Text(
                                      '${med.dosage.isNotEmpty ? '${med.dosage} • ' : ''}${med.frequency == 'daily' ? 'Daily' : 'Custom'} • ${med.timeList.map(formatTime12).join(', ')}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
