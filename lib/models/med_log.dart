class MedLog {
  final int? id;
  final int medicationId;
  final String scheduledTime;
  final String? takenAt;
  final String logDate;

  MedLog({
    this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.takenAt,
    required this.logDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'scheduled_time': scheduledTime,
      'taken_at': takenAt,
      'log_date': logDate,
    };
  }

  factory MedLog.fromMap(Map<String, dynamic> map) {
    return MedLog(
      id: map['id'],
      medicationId: map['medication_id'],
      scheduledTime: map['scheduled_time'],
      takenAt: map['taken_at'],
      logDate: map['log_date'],
    );
  }

  bool get isTaken => takenAt != null;
}