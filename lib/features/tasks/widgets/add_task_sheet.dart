import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/kairos_spinner.dart';
import '../models/task_model.dart';
import '../providers/tasks_provider.dart';

/// Opens the task sheet. This is the app's primary "create a task" entry
/// point — the shell's centre "+" calls it from any tab.
///
/// Deliberately deterministic: unlike the AI quick-capture sheet, this
/// works with no API keys, no network and no orchestrator configured,
/// because it writes straight to the local store (see [TaskActions]).
Future<void> openAddTask(BuildContext context, WidgetRef ref) =>
    openTaskSheet(context, ref);

/// Opens the same sheet to **edit** an existing task.
///
/// One form serves both create and edit on purpose. The fields, the date
/// chips, the time row and the keyboard handling are identical, and a second
/// copy would be one more place for them to drift apart — the app already
/// had four near-identical bottom sheets before this.
Future<void> openEditTask(
  BuildContext context,
  WidgetRef ref,
  TaskModel task,
) =>
    openTaskSheet(context, ref, task: task);

Future<void> openTaskSheet(
  BuildContext context,
  WidgetRef ref, {
  TaskModel? task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // No `backgroundColor` override here on purpose. `bottomSheetTheme`
    // already paints the surface, the 24px top corners and the drag handle;
    // forcing it transparent left the sheet with *no background at all*, so
    // the calendar behind showed straight through the form and the title
    // collided with the task list underneath it.
    builder: (_) => _AddTaskSheet(task: task),
  );
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet({this.task});

  /// Null creates, non-null edits.
  final TaskModel? task;

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  late final _name = TextEditingController(text: widget.task?.name ?? '');
  late final _description =
      TextEditingController(text: widget.task?.description ?? '');

  /// When creating, defaults to today at the next round hour — the
  /// overwhelmingly common case, and it means "add" is one field and one tap.
  /// When editing, starts from the task's own due date.
  late DateTime _due = widget.task?.dueDate ?? _nextRoundHour();
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  static DateTime _nextRoundHour() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void initState() {
    super.initState();
    // Enables/disables the save button as the title becomes (non-)empty.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  void _setDay(DateTime day) {
    setState(() {
      _due = DateTime(day.year, day.month, day.day, _due.hour, _due.minute);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) _setDay(picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (picked != null) {
      setState(() {
        _due = DateTime(
            _due.year, _due.month, _due.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    if (_isEditing) {
      // Edits stay local. The ClickUp mirror is create-only today, so
      // claiming an update synced would be a lie; see the note in
      // TaskActions.
      ref.read(localTasksProvider.notifier).update(
            widget.task!.id,
            name: name,
            description: _description.text.trim(),
            dueDate: _due,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('แก้ไข "$name" แล้ว'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await ref.read(taskActionsProvider).createTask(
          name: name,
          description: _description.text.trim(),
          dueDate: _due,
        );

    if (!mounted) return;
    Navigator.of(context).pop();

    // The task is saved either way — the difference is whether it also
    // reached ClickUp. A failed mirror used to be swallowed entirely, so a
    // user with ClickUp configured was told "saved" while their board
    // quietly went out of sync.
    final failed = result.sync == SyncOutcome.failed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed
              ? 'บันทึก "$name" ในเครื่องแล้ว · ยังไม่ได้ซิงก์ไป ClickUp'
              : 'เพิ่ม "$name" แล้ว',
        ),
        behavior: SnackBarBehavior.floating,
        // Long enough to actually read the sync caveat.
        duration: Duration(seconds: failed ? 6 : 4),
      ),
    );
  }

  /// Deletes the task being edited, with an undo rather than a confirm.
  ///
  /// A confirm dialog on every delete costs a tap on the common path to
  /// protect the rare one. Undo is cheaper for the user and strictly safer:
  /// it also covers the accidental tap the dialog would have been dismissed
  /// through anyway.
  Future<void> _delete() async {
    final task = widget.task!;
    final notifier = ref.read(localTasksProvider.notifier);
    notifier.delete(task.id);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ลบ "${task.name}" แล้ว'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'เลิกทำ',
          // Restores the same content. The id is regenerated — the row is
          // gone from the store — which is fine because nothing outside the
          // store holds a reference to it.
          onPressed: () => notifier.add(
            name: task.name,
            description: task.description,
            dueDate: task.dueDate,
            attendees: task.attendees,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            DesignTokens.screenPadding, 4, DesignTokens.screenPadding, 24),
        child: SafeArea(
          top: false,
          // With the keyboard up there is roughly half a screen left, which
          // is less than this form is tall — without a scroll view the
          // date chips and the save button overflow off the bottom.
          child: SingleChildScrollView(
            // Dragging the form puts the keyboard away. On a phone the
            // keyboard covers the date chips and the save button, and
            // reaching for them is exactly the gesture that should dismiss
            // it — otherwise the user has to hunt for the back gesture first.
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'แก้ไขงาน' : 'เพิ่มงานใหม่',
                        style: text.titleLarge,
                      ),
                    ),
                    if (_isEditing)
                      IconButton(
                        onPressed: _saving ? null : _delete,
                        tooltip: 'ลบงาน',
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: context.colors.error,
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space5),

                _Field(
                  controller: _name,
                  hint: 'ชื่องาน',
                  // Autofocus on create (the field is empty and the user came
                  // here to type). On edit the text already exists, so opening
                  // the keyboard over it hides the thing they came to check.
                  autofocus: !_isEditing,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _description,
                  hint: 'รายละเอียด (ไม่บังคับ)',
                  maxLines: 2,
                  // The last field, so the key commits rather than inserting
                  // a newline into a two-line field nobody scrolls.
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _canSave ? _save() : null,
                ),
                const SizedBox(height: 20),

                Text(
                  'กำหนดส่ง',
                  style: text.labelLarge
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                _DayChips(due: _due, onSelect: _setDay, onPickDate: _pickDate),
                const SizedBox(height: 10),
                _TimeRow(due: _due, onPickTime: _pickTime),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: _saving
                        // Flat onPrimary, not the gradient: on the filled
                        // sage button the gradient's darker stops vanish.
                        ? KairosSpinner(
                            size: 20,
                            strokeWidth: 2.5,
                            color: context.colors.onPrimary,
                          )
                        : Text(_isEditing ? 'บันทึกการแก้ไข' : 'บันทึก'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    // Colors, borders and padding all come from `inputDecorationTheme`.
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(hintText: hint),
    );
  }
}

/// Today / Tomorrow / pick-a-date. Covers the common cases in one tap and
/// falls through to the full picker for anything else.
class _DayChips extends StatelessWidget {
  const _DayChips({
    required this.due,
    required this.onSelect,
    required this.onPickDate,
  });

  final DateTime due;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(due.year, due.month, due.day);
    final isCustom = dueDay != today && dueDay != tomorrow;

    // Wrap, not Row. Three fixed chips fit a wide screen but not a phone once
    // the third one shows a picked date instead of "เลือกวัน" — that row
    // overflowed by 85px on a 412px phone. A second line is free; clipped
    // controls are not.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'วันนี้',
          selected: dueDay == today,
          onTap: () => onSelect(today),
        ),
        _Chip(
          label: 'พรุ่งนี้',
          selected: dueDay == tomorrow,
          onTap: () => onSelect(tomorrow),
        ),
        _Chip(
          label: isCustom ? DateFormat('d MMM').format(due) : 'เลือกวัน',
          selected: isCustom,
          icon: Icons.calendar_today_rounded,
          onTap: onPickDate,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          height: 44, // minimum comfortable hit target
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: context.text.labelLarge?.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.due, required this.onPickTime});

  final DateTime due;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('HH:mm').format(due);
    return Semantics(
      button: true,
      label: 'เลือกเวลา, ตอนนี้ $label',
      child: PressableScale(
        onTap: onPickTime,
        child: Container(
          height: DesignTokens.minTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 18, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'เวลา',
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
              Text(label, style: context.text.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
