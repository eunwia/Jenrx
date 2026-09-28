import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import '../utils/album_colors.dart';
import '../utils/med_icons.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? existing;
  const AddMedicationScreen({super.key, this.existing});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _purposeController = TextEditingController();

  final List<String> _selectedTimes = [];
  bool _everyDay = true;
  final Set<int> _selectedDays = {};
  String _selectedIcon = 'pill';
  String _selectedColor = albumColorHex[0];

  final List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final med = widget.existing;
    if (med != null) {
      _nameController.text = med.name;
      _dosageController.text = med.dosage;
      _purposeController.text = med.purpose;
      _selectedTimes.addAll(med.timeList);
      _selectedIcon = med.icon;
      _selectedColor = med.color;
      if (med.frequency != 'daily') {
        _everyDay = false;
        _selectedDays.addAll(med.frequency.split(',').map(int.parse));
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (!_selectedTimes.contains(formatted)) {
        setState(() {
          _selectedTimes.add(formatted);
          _selectedTimes.sort();
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one time of day.')),
      );
      return;
    }
    if (!_everyDay && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day, or choose Every Day.')),
      );
      return;
    }

    final frequency = _everyDay
        ? 'daily'
        : (_selectedDays.toList()..sort()).join(',');
    final isEditing = widget.existing != null;

    final med = Medication(
      id: isEditing ? widget.existing!.id : null,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      times: _selectedTimes.join(','),
      frequency: frequency,
      icon: _selectedIcon,
      purpose: _purposeController.text.trim(),
      color: _selectedColor,
    );

    if (isEditing) {
      await NotificationService.cancelForMedication(widget.existing!);
      await DatabaseHelper.instance.updateMedication(med);
      await NotificationService.scheduleForMedication(med);
    } else {
      final id = await DatabaseHelper.instance.insertMedication(med);
      await NotificationService.scheduleForMedication(
        Medication(
          id: id,
          name: med.name,
          dosage: med.dosage,
          times: med.times,
          frequency: med.frequency,
          icon: med.icon,
          purpose: med.purpose,
          color: med.color,
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove medication?'),
        content: const Text('Past history will be kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirm == true) {
      await NotificationService.cancelForMedication(widget.existing!);
      await DatabaseHelper.instance.archiveMedication(widget.existing!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final chosen = colorFromHex(_selectedColor);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Medication' : 'Add Medication')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dosageController,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Dosage (optional, e.g. 1 Tablet)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _purposeController,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'For / Purpose (optional)',
                hintText: 'e.g. Mom, My vitamins',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Icon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: medIconOptions.entries.map((entry) {
                final selected = _selectedIcon == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = entry.key),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: selected ? chosen : chosen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(entry.value, color: selected ? Colors.white : chosen),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text('Color', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: albumColorHex.map((hex) {
                final selected = hex == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: colorFromHex(hex),
                      shape: BoxShape.circle,
                      border: selected ? Border.all(color: Colors.black87, width: 3) : null,
                    ),
                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text('Time(s) of Day', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._selectedTimes.map((t) => Chip(
                      label: Text(formatTime12(t), style: const TextStyle(fontSize: 16)),
                      onDeleted: () => setState(() => _selectedTimes.remove(t)),
                    )),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Add Time', style: TextStyle(fontSize: 16)),
                  onPressed: _pickTime,
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Frequency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('Every Day', style: TextStyle(fontSize: 18)),
              value: _everyDay,
              onChanged: (v) => setState(() => _everyDay = v),
            ),
            if (!_everyDay)
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final dayNum = i + 1;
                  final selected = _selectedDays.contains(dayNum);
                  return FilterChip(
                    label: Text(_dayLabels[i], style: const TextStyle(fontSize: 16)),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedDays.add(dayNum);
                      } else {
                        _selectedDays.remove(dayNum);
                      }
                    }),
                  );
                }),
              ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isEditing ? 'Save Changes' : 'Save Medication', style: const TextStyle(fontSize: 20)),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remove Medication', style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}