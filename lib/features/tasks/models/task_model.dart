class TaskModel {
  const TaskModel({
    required this.id,
    required this.name,
    required this.status,
    this.dueDate,
  });

  final String id;
  final String name;
  final String status;
  final DateTime? dueDate;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // ClickUp returns due_date as a millisecond-epoch string, or null.
    final rawDue = json['due_date'] as String?;
    return TaskModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: (json['status'] as Map<String, dynamic>)['status'] as String,
      dueDate: rawDue == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(rawDue)),
    );
  }

  bool get isDueTodayOrTomorrow {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    final daysDiff = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    return daysDiff >= 0 && daysDiff <= 1;
  }
}
