import 'package:flutter_test/flutter_test.dart';
import 'package:med_tracker/models/medication.dart';
import 'package:med_tracker/models/med_log.dart';
import 'package:med_tracker/utils/album_colors.dart';
import 'package:med_tracker/utils/med_icons.dart';
import 'package:med_tracker/theme/app_theme.dart';

void main() {
  group('MedTracker Theme & Utils Unit Tests', () {
    test('AppTheme loads valid light and dark ThemeData', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.useMaterial3, true);
      expect(dark.useMaterial3, true);
      expect(light.primaryColor, AppColors.primary);
      expect(dark.primaryColor, AppColors.primary);
    });

    test('Medication model serialization works correctly', () {
      final med = Medication(
        id: 1,
        name: 'Amlodipine',
        dosage: '5mg',
        times: '08:00,20:00',
        frequency: 'daily',
        icon: 'pill',
        purpose: 'Blood Pressure',
        color: '007AFF',
      );

      final map = med.toMap();
      expect(map['name'], 'Amlodipine');
      expect(map['times'], '08:00,20:00');
      expect(med.timeList, ['08:00', '20:00']);

      final restored = Medication.fromMap(map);
      expect(restored.name, 'Amlodipine');
      expect(restored.dosage, '5mg');
      expect(restored.timeList.length, 2);
    });

    test('MedLog serialization and state check', () {
      final log = MedLog(
        id: 10,
        medicationId: 1,
        scheduledTime: '08:00',
        takenAt: '2026-10-25T08:05:00',
        logDate: '2026-10-25',
      );
      expect(log.isTaken, true);

      final pendingLog = MedLog(
        id: 11,
        medicationId: 1,
        scheduledTime: '20:00',
        logDate: '2026-10-25',
      );
      expect(pendingLog.isTaken, false);
    });

    test('formatTime12 formats correctly', () {
      expect(formatTime12('08:00'), '8:00 AM');
      expect(formatTime12('13:30'), '1:30 PM');
      expect(formatTime12('00:15'), '12:15 AM');
      expect(formatTime12('12:00'), '12:00 PM');
    });

    test('formatDateReadable formats dates safely', () {
      expect(formatDateReadable('2026-10-25'), 'October 25, 2026');
      expect(formatDateReadable('2026-01-01'), 'January 1, 2026');
    });

    test('colorFromHex parses valid and fallback hex', () {
      final color = colorFromHex('007AFF');
      expect(color.toARGB32(), 0xFF007AFF);

      final fallback = colorFromHex('invalid');
      expect(fallback.toARGB32(), 0xFF007AFF);
    });
  });
}
