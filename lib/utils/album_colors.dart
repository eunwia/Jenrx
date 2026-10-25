import 'package:flutter/material.dart';

const List<String> albumColorHex = [
  '007AFF', // Health Blue
  '34C759', // iOS Mint Green
  'FF9500', // iOS Amber Orange
  'FF3B30', // iOS Coral Red
  'AF52DE', // iOS Purple
  '5856D6', // iOS Indigo
  '00C7BE', // iOS Teal
  '8E8E93', // iOS Slate Gray
];

Color colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF007AFF);
  final clean = hex.replaceAll('#', '');
  try {
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
  } catch (_) {}
  return const Color(0xFF007AFF);
}
