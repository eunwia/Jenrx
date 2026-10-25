import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/med_icons.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/empty_state.dart';

class BpScreen extends StatefulWidget {
  const BpScreen({super.key});

  @override
  State<BpScreen> createState() => _BpScreenState();
}

class _BpScreenState extends State<BpScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await DatabaseHelper.instance.getRecentBp(limit: 30);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  String _category(int sys, int dia) {
    if (sys >= 140 || dia >= 90) return 'High';
    if (sys >= 130 || dia >= 80) return 'Elevated';
    return 'Normal';
  }

  BadgeVariant _catVariant(String cat) => switch (cat) {
        'High' => BadgeVariant.danger,
        'Elevated' => BadgeVariant.warning,
        _ => BadgeVariant.success,
      };

  Color _catColor(String cat) => switch (cat) {
        'High' => AppColors.danger,
        'Elevated' => AppColors.warning,
        _ => AppColors.success,
      };

  Future<void> _addReading() async {
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();
    final pulseCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => CustomBottomSheet(
        title: 'Add BP Reading',
        subtitle: 'Enter your latest blood pressure measurement',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sysCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      labelText: 'Systolic (SYS)',
                      hintText: '120',
                      suffixText: 'mmHg',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: diaCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      labelText: 'Diastolic (DIA)',
                      hintText: '80',
                      suffixText: 'mmHg',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pulseCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Pulse / Heart Rate (optional)',
                hintText: '72',
                suffixText: 'BPM',
                prefixIcon: Icon(Icons.favorite_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. After morning rest, before meds',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final sys = int.tryParse(sysCtrl.text);
                  final dia = int.tryParse(diaCtrl.text);
                  if (sys == null || dia == null) return;
                  final pulse = int.tryParse(pulseCtrl.text);
                  final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                  final now = DateTime.now();
                  final db = DatabaseHelper.instance;
                  await db.insertBp(
                    db.formatDate(now),
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    sys,
                    dia,
                    pulse,
                    note,
                  );
                  if (bottomSheetContext.mounted) {
                    Navigator.pop(bottomSheetContext);
                  }
                  if (mounted) _load();
                },
                child: const Text('Save Reading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewDetail(Map<String, dynamic> row) async {
    final sysCtrl = TextEditingController(text: row['systolic'].toString());
    final diaCtrl = TextEditingController(text: row['diastolic'].toString());
    final pulseCtrl = TextEditingController(text: row['pulse']?.toString() ?? '');
    final noteCtrl = TextEditingController(text: row['note'] ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => CustomBottomSheet(
        title: 'Edit BP Reading',
        subtitle: 'Logged on ${formatDateReadable(row['log_date'])} at ${formatTime12(row['log_time'])}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sysCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      labelText: 'Systolic',
                      suffixText: 'mmHg',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: diaCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      labelText: 'Diastolic',
                      suffixText: 'mmHg',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pulseCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Pulse (optional)',
                suffixText: 'BPM',
                prefixIcon: Icon(Icons.favorite_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: bottomSheetContext,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Delete Reading?'),
                          content: const Text('Are you sure you want to delete this reading?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await DatabaseHelper.instance.deleteBp(row['id'] as int);
                        if (bottomSheetContext.mounted) {
                          Navigator.pop(bottomSheetContext);
                        }
                        if (mounted) _load();
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final sys = int.tryParse(sysCtrl.text);
                      final dia = int.tryParse(diaCtrl.text);
                      if (sys == null || dia == null) return;
                      final pulse = int.tryParse(pulseCtrl.text);
                      final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                      await DatabaseHelper.instance.updateBp(
                        row['id'] as int,
                        sys,
                        dia,
                        pulse,
                        note,
                      );
                      if (bottomSheetContext.mounted) {
                        Navigator.pop(bottomSheetContext);
                      }
                      if (mounted) _load();
                    },
                    child: const Text('Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          // Header / Latest Reading Card
          _buildLatestCard(isDark),

          const SizedBox(height: 20),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT READINGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '${_logs.length} logged',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_logs.isEmpty) ...[
            EmptyStateView(
              icon: Icons.favorite_rounded,
              title: 'No BP Readings Yet',
              description: 'Track your blood pressure over time to monitor cardiovascular health.',
              actionLabel: 'Log First Reading',
              onAction: _addReading,
            ),
          ] else ...[
            ..._logs.map((row) => _buildReadingCard(row, isDark)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _addReading,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Log BP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildLatestCard(bool isDark) {
    if (_logs.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Blood Pressure',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Log systolic and diastolic readings with notes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final latest = _logs.first;
    final sys = latest['systolic'] as int;
    final dia = latest['diastolic'] as int;
    final cat = _category(sys, dia);
    final pulse = latest['pulse'] as int?;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LATEST READING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              StatusBadge(
                label: cat,
                variant: _catVariant(cat),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$sys / $dia',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'mmHg',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const Spacer(),
              if (pulse != null) ...[
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$pulse BPM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Recorded ${formatDateReadable(latest['log_date'])} at ${formatTime12(latest['log_time'])}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(Map<String, dynamic> row, bool isDark) {
    final sys = row['systolic'] as int;
    final dia = row['diastolic'] as int;
    final cat = _category(sys, dia);
    final note = row['note'] as String?;
    final pulse = row['pulse'] as int?;
    final catColor = _catColor(cat);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => _viewDetail(row),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.favorite_rounded, color: catColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$sys / $dia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: cat,
                        variant: _catVariant(cat),
                        fontSize: 11,
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      ),
                      if (pulse != null) ...[
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              '$pulse',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDateReadable(row['log_date'])} • ${formatTime12(row['log_time'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
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
}
