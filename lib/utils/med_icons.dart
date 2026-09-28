import 'package:flutter/material.dart';

const Map<String, IconData> medIconOptions = {
  'pill': Icons.medication,
  'capsule': Icons.medication_liquid,
  'syrup': Icons.local_drink,
  'injection': Icons.vaccines,
  'drops': Icons.opacity,
  'heart': Icons.favorite,
};

IconData iconForKey(String? key) => medIconOptions[key] ?? Icons.medication;

String formatTime12(String time24) {
  final parts = time24.split(':');
  int hour = int.parse(parts[0]);
  final minute = parts[1];
  final period = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '$hour:$minute $period';
}

String formatDateReadable(String isoDate) {
  final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  final parts = isoDate.split('-');
  final year = parts[0];
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  return '${months[month - 1]} $day, $year';
}