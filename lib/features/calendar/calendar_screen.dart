import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../tasks/models/task_model.dart';
import '../tasks/providers/tasks_provider.dart';
import '../tasks/widgets/add_task_sheet.dart';

/// Timeline / calendar page — the second screen of the
/// `homepage_and_calender` reference. A light \"Today\" header with a
/// horizontal date strip and a vertical timeline of the day's items.
///
/// The homepage half of that mockup is already implemented by
/// [DashboardScreen], so this page delivers the calendar half. It's the
/// screen behind the bottom nav's \"docs\" tab (index 1).
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  /// Seven days centered on the selected one.
  late final List<DateTime> _days;
  int _selected = 3; // "today" sits 4th in the strip, matching the mockup

  @override
  void initState() {
    super.initState();
    final base = DateTime.now();
    _days = List.generate(7, (i) => DateTime(base.year, base.month, base.day + (i - _selected)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _days[_selected];
    // The timeline is the local task store filtered to the selected day —
    // the same store the "+" sheet writes to, so a new task shows up here
    // the moment it's saved.
    final tasks = ref.watch(tasksForDayProvider(selectedDate));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(date: selectedDate),
          _DateStrip(
            days: _days,
            selected: _selected,
            onSelect: (i) => setState(() => _selected = i),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tasks.isEmpty
                ? _EmptyDay(onAdd: () => openAddTask(context, ref))
                : ListView.builder(
                    // Bottom padding clears the shell's floating nav bar.
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) => _TimelineRow(
                      task: tasks[i],
                      // The first task of the day gets the hero treatment.
                      featured: i == 0,
                      isLast: i == tasks.length - 1,
                      onToggleDone: () => ref
                          .read(localTasksProvider.notifier)
                          .toggleDone(tasks[i].id),
                      onEdit: () => openEditTask(context, ref, tasks[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded,
                size: 40, color: context.colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีงานในวันนี้',
              style: text.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('เพิ่มงาน'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Header ----------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(date),
                  style: context.text.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeLabel(date),
                  style: context.text.displayMedium,
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(Icons.person_rounded,
                size: 22, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _relativeLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat('EEEE').format(d);
  }
}

// --- Horizontal date strip -------------------------------------------------

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.days, required this.selected, required this.onSelect});

  final List<DateTime> days;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          final active = i == selected;
          final fg = active ? cs.onPrimary : cs.onSurfaceVariant;
          return Semantics(
            button: true,
            selected: active,
            label: DateFormat('EEEE d MMMM').format(d),
            child: GestureDetector(
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? 52 : 44,
                decoration: BoxDecoration(
                  color: active ? cs.primary : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('d').format(d),
                      style: context.text.labelLarge?.copyWith(
                        color: fg,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('E').format(d).substring(0, 3),
                      style: context.text.labelSmall?.copyWith(color: fg),
                    ),
                    if (active) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: cs.onPrimary, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Timeline --------------------------------------------------------------

/// Formats a task's due time for the timeline, e.g. "9.00 AM".
String _timeLabel(TaskModel task) {
  final due = task.dueDate;
  return due == null ? '' : DateFormat('h.mm a').format(due);
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.task,
    required this.featured,
    required this.isLast,
    required this.onToggleDone,
    required this.onEdit,
  });

  final TaskModel task;
  final bool featured;
  final bool isLast;
  final VoidCallback onToggleDone;

  /// Tapping the card body opens the editor. The done button keeps its own
  /// tap target, so completing a task never opens a form by accident.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node + connecting line.
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: featured
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: featured ? cs.primary : cs.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: cs.outlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28, top: 2),
              child: featured
                  ? _FeaturedCard(
                      task: task,
                      onToggleDone: onToggleDone,
                      onEdit: onEdit,
                    )
                  : _PlainItem(
                      task: task,
                      onToggleDone: onToggleDone,
                      onEdit: onEdit,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.task,
    required this.onToggleDone,
    required this.onEdit,
  });
  final TaskModel task;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final palette = context.palette;
    return Semantics(
      button: true,
      label: 'แก้ไข ${task.name}',
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.name,
                  style: context.text.titleMedium?.copyWith(
                    color: palette.onHero,
                    fontWeight: FontWeight.w700,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(_timeLabel(task),
                  style: context.text.bodySmall
                      ?.copyWith(color: palette.onHeroVariant)),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              style: context.text.bodySmall
                  ?.copyWith(color: palette.onHeroVariant, height: 1.4),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AvatarStack(count: task.attendees),
              _DoneButton(done: task.done, onTap: onToggleDone, onBrand: true),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}

/// Marks a task complete. The one interactive control on a timeline row,
/// so it carries the semantics and a full-size hit target.
class _DoneButton extends StatelessWidget {
  const _DoneButton({
    required this.done,
    required this.onTap,
    this.onBrand = false,
  });

  final bool done;
  final VoidCallback onTap;

  /// True when sitting on the brand gradient, where the palette inverts.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final palette = context.palette;
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'ทำเสร็จแล้ว แตะเพื่อยกเลิก' : 'ทำเครื่องหมายว่าเสร็จ',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        child: Padding(
          // Pads a 32px visual control out to a 48px touch target.
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: onBrand
                  ? palette.onHero
                  : (done ? cs.primary : cs.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(10),
              border: onBrand || done
                  ? null
                  : Border.all(color: cs.outline, width: 2),
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: onBrand
                  ? (done ? cs.primary : cs.primary.withValues(alpha: 0.35))
                  : (done ? cs.onPrimary : cs.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SizedBox(
      height: 32,
      width: count == 0 ? 0 : 32.0 + (count - 1) * 22,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: i * 22.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary, width: 2),
                ),
                child: Icon(Icons.person_rounded,
                    size: 16, color: cs.onSecondaryContainer),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlainItem extends StatelessWidget {
  const _PlainItem({
    required this.task,
    required this.onToggleDone,
    required this.onEdit,
  });
  final TaskModel task;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          // opaque so the whole text block is tappable, including the gaps
          // between the title and description.
          child: Semantics(
            button: true,
            label: 'แก้ไข ${task.name}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      style: context.text.titleMedium?.copyWith(
                        color: task.done ? cs.onSurfaceVariant : cs.onSurface,
                        fontWeight: FontWeight.w700,
                        decoration:
                            task.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_timeLabel(task),
                      style: context.text.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(task.description,
                    style: context.text.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
              ],
            ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _DoneButton(done: task.done, onTap: onToggleDone),
      ],
    );
  }
}
