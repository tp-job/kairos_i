import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bento_card.dart';
import '../models/task_model.dart';
import '../providers/tasks_provider.dart';

class TasksCard extends ConsumerWidget {
  const TasksCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    return BentoCard(
      title: 'งานที่ต้องส่ง',
      icon: Icons.checklist_rounded,
      onTap: () => ref.invalidate(tasksProvider),
      child: AsyncCardBody<List<TaskModel>>(
        value: tasks,
        builder: (context, data) {
          if (data.isEmpty) {
            return const Center(
              child: Text('ไม่มีงานที่ต้องส่งวันนี้/พรุ่งนี้ 🎉'),
            );
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, _) => const Divider(height: 12),
            itemBuilder: (context, i) => _TaskRow(task: data[i]),
          );
        },
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final due = task.dueDate;
    return Row(
      children: [
        Expanded(
          child: Text(
            task.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (due != null)
          Text(
            DateFormat('d MMM · HH:mm').format(due),
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
      ],
    );
  }
}
