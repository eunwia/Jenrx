import '../utils/med_icons.dart';

class Appointment {
  final int? id;
  final String title;
  final String hospital;
  final String? doctor;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm (24-hour)
  final String? location;
  final String? notes;
  final int reminderMinutes; // e.g. 60 (1 hr), 1440 (1 day), 0 (none)

  Appointment({
    this.id,
    required this.title,
    required this.hospital,
    this.doctor,
    required this.date,
    required this.time,
    this.location,
    this.notes,
    this.reminderMinutes = 60,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'hospital': hospital,
      'doctor': doctor,
      'date': date,
      'time': time,
      'location': location,
      'notes': notes,
      'reminder_minutes': reminderMinutes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as int?,
      title: map['title'] as String,
      hospital: map['hospital'] as String,
      doctor: map['doctor'] as String?,
      date: map['date'] as String,
      time: map['time'] as String,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      reminderMinutes: (map['reminder_minutes'] as int?) ?? 60,
    );
  }

  Appointment copyWith({
    int? id,
    String? title,
    String? hospital,
    String? doctor,
    String? date,
    String? time,
    String? location,
    String? notes,
    int? reminderMinutes,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      hospital: hospital ?? this.hospital,
      doctor: doctor ?? this.doctor,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }

  String get formattedTime => formatTime12(time);

  String get formattedDate => formatDateReadable(date);

  String get reminderLabel {
    switch (reminderMinutes) {
      case 0:
        return 'No reminder';
      case 30:
        return '30 minutes before';
      case 60:
        return '1 hour before';
      case 120:
        return '2 hours before';
      case 1440:
        return '1 day before';
      default:
        return '$reminderMinutes min before';
    }
  }
}
