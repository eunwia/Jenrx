import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/medication.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleForMedication(Medication med) async {
    for (int i = 0; i < med.timeList.length; i++) {
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
          android: AndroidNotificationDetails('med_reminders', 'Medication Reminders',
              importance: Importance.high, priority: Priority.high),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelForMedication(Medication med) async {
    for (int i = 0; i < med.timeList.length; i++) {
      await _plugin.cancel((med.id! * 10) + i);
    }
  }
}