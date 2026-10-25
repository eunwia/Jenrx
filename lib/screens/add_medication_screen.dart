import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/album_colors.dart';
import '../utils/med_icons.dart';
import '../widgets/app_card.dart';

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
    } else {
      _selectedTimes.add('08:00'); // Sensible default morning time
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
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
        SnackBar(
          content: const Text('Please add at least one scheduled time.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (!_everyDay && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pick at least one day, or choose Every Day.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Medication?'),
        content: const Text('This medication will be archived. Past dose history and compliance records will be safely preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await NotificationService.cancelForMedication(widget.existing!);
      await DatabaseHelper.instance.archiveMedication(widget.existing!.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chosenColor = colorFromHex(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medication' : 'Add Medication'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Interactive Live Preview Card
            _buildLivePreview(chosenColor, isDark),
            const SizedBox(height: 20),

            // Section 1: Medication Details
            _buildSectionHeader('MEDICATION DETAILS', isDark),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Medicine Name *',
                      hintText: 'e.g. Amlodipine, Vitamin C',
                      prefixIcon: Icon(iconForKey(_selectedIcon), color: chosenColor),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter medicine name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _dosageController,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Dosage / Strength',
                      hintText: 'e.g. 500 mg, 1 Tablet, 5 ml',
                      prefixIcon: Icon(Icons.scale_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _purposeController,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Purpose / Tag (optional)',
                      hintText: 'e.g. Blood Pressure, For Mom, Night',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Icon & Appearance
            _buildSectionHeader('ICON & COLOR', isDark),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Icon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: medIconOptions.entries.map((entry) {
                      final selected = _selectedIcon == entry.key;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: selected
                                ? chosenColor
                                : (isDark ? AppColors.darkSurfaceSubtle : chosenColor.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? chosenColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            color: selected ? Colors.white : chosenColor,
                            size: 24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select Accent Color',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: albumColorHex.map((hex) {
                      final selected = hex == _selectedColor;
                      final swatchColor = colorFromHex(hex);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: swatchColor,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: swatchColor.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Schedule & Times
            _buildSectionHeader('SCHEDULE & REMINDER TIMES', isDark),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scheduled Times',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: _pickTime,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Time'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._selectedTimes.map((t) => Chip(
                            backgroundColor: isDark
                                ? AppColors.darkSurfaceSubtle
                                : AppColors.primaryLight,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            label: Text(
                              formatTime12(t),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            deleteIconColor: AppColors.primary,
                            onDeleted: () => setState(() => _selectedTimes.remove(t)),
                          )),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repeat Schedule',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            _everyDay ? 'Every single day' : 'Specific days of the week',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _everyDay,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _everyDay = v),
                      ),
                    ],
                  ),
                  if (!_everyDay) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final dayNum = i + 1;
                        final selected = _selectedDays.contains(dayNum);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedDays.remove(dayNum);
                            } else {
                              _selectedDays.add(dayNum);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF0F4F8)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _dayLabels[i][0],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Add Medication',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            if (isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text(
                    'Remove Medication',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview(Color chosenColor, bool isDark) {
    final name = _nameController.text.trim().isEmpty
        ? 'Medication Preview'
        : _nameController.text.trim();
    final dosage = _dosageController.text.trim().isEmpty
        ? 'Dose will appear here'
        : _dosageController.text.trim();
    final purpose = _purposeController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('LIVE PREVIEW', isDark),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: chosenColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: chosenColor.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: chosenColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconForKey(_selectedIcon), color: chosenColor, size: 26),
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
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (purpose.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: chosenColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              purpose,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: chosenColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dosage,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 26),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
