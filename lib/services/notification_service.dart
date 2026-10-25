import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/medication.dart';
import '../models/appointment.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  static Future<void> scheduleForMedication(Medication med) async {
    if (med.id == null) return;
    for (int i = 0; i < med.timeList.length; i++) {
      try {
        final parts = med.timeList[i].split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final id = (med.id! * 10) + i; // unique id per med+time slot

        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

        await _plugin.zonedSchedule(
          id,
          'Medication Reminder',
          '${med.name} — ${med.dosage}',
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'med_reminders',
              'Medication Reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  static Future<void> cancelForMedication(Medication med) async {
    if (med.id == null) return;
    for (int i = 0; i < med.timeList.length; i++) {
      try {
        await _plugin.cancel((med.id! * 10) + i);
      } catch (_) {}
    }
  }

  static Future<void> scheduleForAppointment(Appointment appt) async {
    if (appt.id == null || appt.reminderMinutes <= 0) return;
    try {
      final dateParts = appt.date.split('-');
      final timeParts = appt.time.split(':');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final appointmentDateTime = tz.TZDateTime(tz.local, year, month, day, hour, minute);
      final reminderTime = appointmentDateTime.subtract(Duration(minutes: appt.reminderMinutes));

      final now = tz.TZDateTime.now(tz.local);
      if (reminderTime.isBefore(now)) return;

      final notificationId = 100000 + appt.id!;

      await _plugin.zonedSchedule(
        notificationId,
        'Hospital Appointment: ${appt.title}',
        'At ${appt.hospital} • ${appt.time}',
        reminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Hospital Appointments',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  static Future<void> cancelForAppointment(int id) async {
    try {
      await _plugin.cancel(100000 + id);
    } catch (_) {}
  }
}
