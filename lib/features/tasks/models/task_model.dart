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

  /// Round-trips a locally-created task through `shared_preferences`.
  ///
  /// Deliberately *not* [fromJson]: that one parses ClickUp's wire format,
  /// where status is a nested object and `due_date` is an epoch string.
  /// Sharing one shape between an external API and our own storage means a
  /// change on their side silently corrupts the local store.
  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'name': name,
        'status': status,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'done': done,
        'attendees': attendees,
        'source': source.name,
      };

  factory TaskModel.fromStorageJson(Map<String, dynamic> json) {
    final rawDue = json['dueDate'] as String?;
    return TaskModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? 'to do',
      description: json['description'] as String? ?? '',
      dueDate: rawDue == null ? null : DateTime.parse(rawDue),
      done: json['done'] as bool? ?? false,
      attendees: json['attendees'] as int? ?? 0,
      source: TaskSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => TaskSource.local,
      ),
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
