import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_tracker/models/medication.dart';
import 'package:med_tracker/models/med_log.dart';
import 'package:med_tracker/models/appointment.dart';
import 'package:med_tracker/services/app_settings.dart';
import 'package:med_tracker/utils/album_colors.dart';
import 'package:med_tracker/utils/med_icons.dart';
import 'package:med_tracker/theme/app_theme.dart';
import 'package:med_tracker/widgets/mascot_companion.dart';
import 'package:med_tracker/widgets/interactive_medicine_kit.dart';

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

    testWidgets('MascotCompanion renders with different moods', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MascotCompanion(
              mood: CompanionMood.allCompleted,
            ),
          ),
        ),
      );
      expect(find.textContaining('PIP • HEALTH GUARDIAN'), findsOneWidget);
      expect(find.textContaining('All done for today!'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MascotCompanion(
              mood: CompanionMood.upcoming,
              nextMedName: 'Amlodipine',
              nextMedTime: '8:00 AM',
            ),
          ),
        ),
      );
      expect(find.textContaining('Next dose: Amlodipine at 8:00 AM'), findsOneWidget);
    });

    test('Appointment model serialization and formatting', () {
      final appt = Appointment(
        id: 1,
        title: 'Cardiology Follow-up',
        hospital: 'St. Luke Medical Center',
        doctor: 'Dr. Santos',
        date: '2026-11-15',
        time: '14:30',
        location: 'Room 402, Heart Center',
        notes: 'Bring previous ECG results',
        reminderMinutes: 60,
      );

      final map = appt.toMap();
      expect(map['title'], 'Cardiology Follow-up');
      expect(map['hospital'], 'St. Luke Medical Center');
      expect(map['reminder_minutes'], 60);

      final restored = Appointment.fromMap(map);
      expect(restored.formattedTime, '2:30 PM');
      expect(restored.formattedDate, 'November 15, 2026');
      expect(restored.reminderLabel, '1 hour before');
    });

    test('AppTextSize enum and scale factors', () {
      expect(AppTextSize.small.scaleFactor, 0.88);
      expect(AppTextSize.medium.scaleFactor, 1.0);
      expect(AppTextSize.large.scaleFactor, 1.18);
      expect(AppTextSize.values.length, 3);
    });

    testWidgets('InteractiveMedicineKit renders closed and transitions to open state', (tester) async {
      bool animationCompleted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveMedicineKit(
              totalItems: 4,
              lowStockCount: 1,
              onAnimationComplete: () => animationCompleted = true,
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveMedicineKit), findsOneWidget);
      expect(find.textContaining('Medicine Kit'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(animationCompleted, true);
      expect(find.textContaining('Pip • Medicine Kit Guardian'), findsOneWidget);
      expect(find.textContaining('running low'), findsOneWidget);

      await tester.tap(find.byType(InteractiveMedicineKit));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('InteractiveMedicineKit respects reduced motion immediately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: InteractiveMedicineKit(
                totalItems: 0,
                lowStockCount: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Pip • Medicine Kit Guardian'), findsOneWidget);
      expect(find.textContaining('Kit is empty'), findsOneWidget);
    });
  });
}
