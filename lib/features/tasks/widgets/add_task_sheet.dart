import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/kairos_spinner.dart';
import '../providers/tasks_provider.dart';

/// Opens the add-task sheet. This is the app's primary "create a task"
/// entry point — the shell's centre "+" calls it from any tab.
///
/// Deliberately deterministic: unlike the AI quick-capture sheet, this
/// works with no API keys, no network and no orchestrator configured,
/// because it writes straight to the local store (see [TaskActions]).
Future<void> openAddTask(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // No `backgroundColor` override here on purpose. `bottomSheetTheme`
    // already paints the surface, the 24px top corners and the drag handle;
    // forcing it transparent left the sheet with *no background at all*, so
    // the calendar behind showed straight through the form and the title
    // collided with the task list underneath it.
    builder: (_) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet();

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  /// Defaults to today at the next round hour — the overwhelmingly common
  /// case, and it means "add" is one field and one tap.
  late DateTime _due = _nextRoundHour();
  bool _saving = false;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('เพิ่มงานใหม่', style: text.titleLarge),
                const SizedBox(height: DesignTokens.space5),

                _Field(
                  controller: _name,
                  hint: 'ชื่องาน',
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _description,
                  hint: 'รายละเอียด (ไม่บังคับ)',
                  maxLines: 2,
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
                        : const Text('บันทึก'),
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

    return Row(
      children: [
        _Chip(
          label: 'วันนี้',
          selected: dueDay == today,
          onTap: () => onSelect(today),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'พรุ่งนี้',
          selected: dueDay == tomorrow,
          onTap: () => onSelect(tomorrow),
        ),
        const SizedBox(width: 8),
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
