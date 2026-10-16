class HabitLog {
  final String id;
  final String date;

  const HabitLog({required this.id, required this.date});

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['documentId'] as String,
      date: json['date'] as String,
    );
  }
}
