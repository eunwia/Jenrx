class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String times;
  final String frequency;
  final int isArchived;
  final String icon;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.frequency,
    this.isArchived = 0,
    this.icon = 'pill',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'times': times,
      'frequency': frequency,
      'is_archived': isArchived,
      'icon': icon,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      times: map['times'],
      frequency: map['frequency'],
      isArchived: map['is_archived'],
      icon: map['icon'] ?? 'pill',
    );
  }

  List<String> get timeList => times.split(',');
}