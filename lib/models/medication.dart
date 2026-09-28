class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String times;
  final String frequency;
  final int isArchived;
  final String icon;
  final String purpose;

  Medication({
    this.id,
    required this.name,
    this.dosage = '',
    required this.times,
    required this.frequency,
    this.isArchived = 0,
    this.icon = 'pill',
    this.purpose = '',
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
      'purpose': purpose,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: (map['dosage'] as String?) ?? '',
      times: map['times'],
      frequency: map['frequency'],
      isArchived: map['is_archived'],
      icon: (map['icon'] as String?) ?? 'pill',
      purpose: (map['purpose'] as String?) ?? '',
    );
  }

  List<String> get timeList => times.split(',');
}