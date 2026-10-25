import 'package:flutter/material.dart';

const Map<String, IconData> medIconOptions = {
  'pill': Icons.medication_rounded,
  'capsule': Icons.medication_liquid_rounded,
  'syrup': Icons.local_drink_rounded,
  'injection': Icons.vaccines_rounded,
  'drops': Icons.opacity_rounded,
  'heart': Icons.favorite_rounded,
};

IconData iconForKey(String? key) => medIconOptions[key] ?? Icons.medication_rounded;

String formatTime12(String time24) {
  try {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  } catch (_) {
    return time24;
  }
}

String formatDateReadable(String isoDate) {
  try {
    final clean = isoDate.split('T')[0].split(' ')[0];
    final parts = clean.split('-');
    if (parts.length < 3) return isoDate;
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final year = parts[0];
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return '${months[month - 1]} $day, $year';
  } catch (_) {
    return isoDate;
  }
}
