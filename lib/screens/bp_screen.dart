import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../utils/med_icons.dart';

class BpScreen extends StatefulWidget {
  const BpScreen({super.key});
  @override
  State<BpScreen> createState() => _BpScreenState();
}

class _BpScreenState extends State<BpScreen> {
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final logs = await DatabaseHelper.instance.getRecentBp(limit: 30);
    setState(() => _logs = logs);
  }

  String _category(int sys, int dia) {
    if (sys >= 140 || dia >= 90) return 'High';
    if (sys >= 130 || dia >= 80) return 'Elevated';
    return 'Normal';
  }

  Color _catColor(String cat) => switch (cat) {
        'High' => Colors.red,
        'Elevated' => Colors.orange,
        _ => Colors.green,
      };

  Widget _header(Color textColor) {
    String subtitle = 'Tap + to add your first reading';
    if (_logs.isNotEmpty) {
      final l = _logs.first;
      final sys = l['systolic'] as int;
      final dia = l['diastolic'] as int;
      subtitle = 'Latest: $sys/$dia • ${_category(sys, dia)}';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Track your blood pressure',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('${_logs.length} ${_logs.length == 1 ? 'reading' : 'readings'}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF1565F5), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Image.asset('assets/images/jen_bp.png', height: 110),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> row, Color textColor) {
    final sys = row['systolic'] as int;
    final dia = row['diastolic'] as int;
    final cat = _category(sys, dia);
    final note = row['note'] as String?;

    return GestureDetector(
      onTap: () => _viewDetail(row),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: _catColor(cat).withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.favorite, color: _catColor(cat), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$sys/$dia', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: _catColor(cat).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(cat, style: TextStyle(color: _catColor(cat), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDateReadable(row['log_date'])} • ${formatTime12(row['log_time'])}'
                    '${row['pulse'] != null ? ' • Pulse: ${row['pulse']}' : ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 6),
                    Text(note, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[700])),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addReading() async {
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();
    final pulseCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add BP Reading', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: sysCtrl, keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(labelText: 'Systolic', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: diaCtrl, keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(labelText: 'Diastolic', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: pulseCtrl, keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Pulse (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: noteCtrl, style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                    labelText: 'Note (optional)', hintText: 'e.g. before maintenance, after walk',
                    border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565F5), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final sys = int.tryParse(sysCtrl.text);
                  final dia = int.tryParse(diaCtrl.text);
                  if (sys == null || dia == null) return;
                  final pulse = int.tryParse(pulseCtrl.text);
                  final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                  final now = DateTime.now();
                  final db = DatabaseHelper.instance;
                  await db.insertBp(db.formatDate(now),
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                      sys, dia, pulse, note);
                  if (mounted) Navigator.pop(context);
                  _load();
                },
                child: const Text('Save Reading', style: TextStyle(fontSize: 18)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit BP Reading', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Logged on ${formatDateReadable(row['log_date'])} at ${formatTime12(row['log_time'])}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: sysCtrl, keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(labelText: 'Systolic', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: diaCtrl, keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(labelText: 'Diastolic', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: pulseCtrl, keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Pulse (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: noteCtrl, style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete reading?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await DatabaseHelper.instance.deleteBp(row['id'] as int);
                        if (mounted) Navigator.pop(context);
                        _load();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565F5), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final sys = int.tryParse(sysCtrl.text);
                      final dia = int.tryParse(diaCtrl.text);
                      if (sys == null || dia == null) return;
                      final pulse = int.tryParse(pulseCtrl.text);
                      final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                      await DatabaseHelper.instance.updateBp(row['id'] as int, sys, dia, pulse, note);
                      if (mounted) Navigator.pop(context);
                      _load();
                    },
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return Scaffold(
      //appBar: AppBar(title: const Text('Blood Pressure')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(textColor),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('No readings yet.', style: TextStyle(fontSize: 18, color: Colors.grey))),
            )
          else
            ..._logs.map((row) => _card(row, textColor)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565F5),
        onPressed: _addReading,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}