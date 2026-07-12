/// Feature 1.1 Auto-Role Switching: the four expert "hats" the
/// orchestrator can wear. The AI picks one per user message based on
/// keywords/intent — the app never shows a mode switcher UI for it.
enum AssistantRole { weather, tasks, techNews, market, general }

extension AssistantRoleLabel on AssistantRole {
  String get thaiLabel => switch (this) {
        AssistantRole.weather => 'ผู้เชี่ยวชาญสภาพอากาศ',
        AssistantRole.tasks => 'ผู้ช่วยจัดการงาน',
        AssistantRole.techNews => 'นักสรุปข่าวเทค',
        AssistantRole.market => 'นักวิเคราะห์การเงิน',
        AssistantRole.general => 'ผู้ช่วยทั่วไป',
      };
}

/// Feature 1.2 NLP: the structured shape a free-text command like
/// "พรุ่งนี้บ่ายโมงมีนัดส่งงาน" gets parsed into before it's routed to
/// a concrete action (e.g. ClickUpService.createTask).
class ParsedIntent {
  const ParsedIntent({
    required this.role,
    required this.action,
    this.taskName,
    this.dueDate,
    this.replyText,
  });

  final AssistantRole role;

  /// One of: "create_task", "answer_question", "none".
  /// Kept as a string (not another enum) so the AI's JSON output maps
  /// onto it directly without a brittle allow-list of exact enum names.
  final String action;

  final String? taskName;
  final DateTime? dueDate;

  /// Free-text reply to show the user directly, when the intent is
  /// just a question rather than an action (e.g. "อากาศพรุ่งนี้เป็นไง").
  final String? replyText;

  factory ParsedIntent.fromJson(Map<String, dynamic> json) {
    return ParsedIntent(
      role: AssistantRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => AssistantRole.general,
      ),
      action: json['action'] as String? ?? 'none',
      taskName: json['task_name'] as String?,
      dueDate: json['due_date'] == null
          ? null
          : DateTime.tryParse(json['due_date'] as String),
      replyText: json['reply_text'] as String?,
    );
  }
}
