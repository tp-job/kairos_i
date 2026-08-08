/// Where a task came from. Local tasks are created in-app and always
/// work; ClickUp tasks arrive from the API and need credentials in .env.
enum TaskSource { local, clickUp }

class TaskModel {
  const TaskModel({
    required this.id,
    required this.name,
    required this.status,
    this.description = '',
    this.dueDate,
    this.done = false,
    this.attendees = 0,
    this.source = TaskSource.local,
  });

  final String id;
  final String name;
  final String status;

  /// Optional one-line detail shown under the title on the timeline.
  final String description;
  final DateTime? dueDate;
  final bool done;

  /// People on the task — drives the avatar stack on the featured card.
  final int attendees;
  final TaskSource source;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // ClickUp returns due_date as a millisecond-epoch string, or null.
    final rawDue = json['due_date'] as String?;
    final status = (json['status'] as Map<String, dynamic>)['status'] as String;
    return TaskModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: status,
      description: (json['description'] as String?)?.trim() ?? '',
      dueDate: rawDue == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(rawDue)),
      done: status.toLowerCase() == 'complete' ||
          status.toLowerCase() == 'closed',
      source: TaskSource.clickUp,
    );
  }

  TaskModel copyWith({
    String? name,
    String? status,
    String? description,
    DateTime? dueDate,
    bool? done,
    int? attendees,
  }) {
    return TaskModel(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      done: done ?? this.done,
      attendees: attendees ?? this.attendees,
      source: source,
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

  /// True when this task is due on [day] (date only, time ignored).
  bool isOn(DateTime day) {
    final due = dueDate;
    if (due == null) return false;
    return due.year == day.year && due.month == day.month && due.day == day.day;
  }
}
