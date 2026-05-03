import 'dart:convert';

class OvertimeEntry {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final double hours;
  final String tasks;
  final double? hourlyRate;
  final DateTime createdAt;

  OvertimeEntry({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.hours,
    required this.tasks,
    this.hourlyRate,
    required this.createdAt,
  });

  double get totalPay => hourlyRate != null ? hours * hourlyRate! : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'hours': hours,
      'tasks': tasks,
      'hourlyRate': hourlyRate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OvertimeEntry.fromMap(Map<String, dynamic> map) {
    return OvertimeEntry(
      id: map['id'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      hours: (map['hours'] as num).toDouble(),
      tasks: map['tasks'],
      hourlyRate: map['hourlyRate'] != null
          ? (map['hourlyRate'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory OvertimeEntry.fromJson(String source) =>
      OvertimeEntry.fromMap(json.decode(source));
}
