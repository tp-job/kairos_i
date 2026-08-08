// Tests for the local (no-API) add-task feature: the store creates,
// filters and completes tasks, and the "+" sheet drives the same store
// end to end — all without ClickUp credentials or a network.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/features/calendar/calendar_screen.dart';
import 'package:kairos_i/features/tasks/providers/tasks_provider.dart';
import 'package:kairos_i/features/tasks/widgets/add_task_sheet.dart';

Widget _wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

/// A bare host with a button that opens the add-task sheet, so the sheet
/// can be exercised without booting the whole shell.
class _SheetHost extends ConsumerWidget {
  const _SheetHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => openAddTask(context, ref),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  group('LocalTasksNotifier', () {
    test('add() creates a task and keeps the list sorted by due date', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localTasksProvider.notifier);

      final now = DateTime.now();
      // 08:00 sorts before every seeded task (earliest is 09:00).
      notifier.add(
        name: 'Early standup',
        dueDate: DateTime(now.year, now.month, now.day, 8),
      );

      final tasks = container.read(localTasksProvider);
      expect(tasks.first.name, 'Early standup');
      expect(tasks.first.done, isFalse);
      expect(tasks.length, 5); // 4 seeded + 1
    });

    test('undated tasks sort last', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localTasksProvider.notifier).add(name: 'Someday');

      expect(container.read(localTasksProvider).last.name, 'Someday');
    });

    test('toggleDone flips done and status both ways', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localTasksProvider.notifier);

      final task = notifier.add(name: 'Ship it', dueDate: DateTime.now());
      expect(task.done, isFalse);

      notifier.toggleDone(task.id);
      var stored =
          container.read(localTasksProvider).firstWhere((t) => t.id == task.id);
      expect(stored.done, isTrue);
      expect(stored.status, 'complete');

      notifier.toggleDone(task.id);
      stored =
          container.read(localTasksProvider).firstWhere((t) => t.id == task.id);
      expect(stored.done, isFalse);
      expect(stored.status, 'to do');
    });

    test('delete removes only the target task', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localTasksProvider.notifier);

      final task = notifier.add(name: 'Temp', dueDate: DateTime.now());
      final before = container.read(localTasksProvider).length;

      notifier.delete(task.id);

      final after = container.read(localTasksProvider);
      expect(after.length, before - 1);
      expect(after.any((t) => t.id == task.id), isFalse);
    });
  });

  group('tasksForDayProvider', () {
    test('returns only tasks due on the given day', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final today = DateTime.now();
      final nextWeek = today.add(const Duration(days: 7));
      container
          .read(localTasksProvider.notifier)
          .add(name: 'Next week thing', dueDate: nextWeek);

      final todays = container.read(tasksForDayProvider(today));
      final laters = container.read(tasksForDayProvider(nextWeek));

      expect(todays.length, 4); // the seeded four
      expect(todays.any((t) => t.name == 'Next week thing'), isFalse);
      expect(laters.map((t) => t.name), ['Next week thing']);
    });
  });

  group('add-task sheet', () {
    testWidgets('saving a task writes it to the store', (tester) async {
      await tester.pumpWidget(_wrap(const _SheetHost()));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('เพิ่มงานใหม่'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'ส่งรายงาน');
      await tester.pumpAndSettle();

      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      // Sheet closes and the task exists in the store.
      expect(find.text('เพิ่มงานใหม่'), findsNothing);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(_SheetHost)),
      );
      expect(
        container.read(localTasksProvider).any((t) => t.name == 'ส่งรายงาน'),
        isTrue,
      );
    });

    testWidgets('save stays disabled while the title is blank',
        (tester) async {
      await tester.pumpWidget(_wrap(const _SheetHost()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'อะไรสักอย่าง');
      await tester.pumpAndSettle();

      final enabled = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets('whitespace-only titles are rejected', (tester) async {
      await tester.pumpWidget(_wrap(const _SheetHost()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('CalendarScreen', () {
    testWidgets('renders the seeded timeline', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Meeting'), findsOneWidget);
      expect(find.text('Check asset'), findsOneWidget);
    });

    testWidgets('a newly added task appears on the timeline', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarScreen()));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarScreen)),
      );
      final now = DateTime.now();
      // 07:00 sorts ahead of every seeded task, so the new row renders at
      // the top of the timeline rather than below the test viewport's fold
      // (ListView.builder never builds off-screen children).
      container.read(localTasksProvider.notifier).add(
            name: 'งานใหม่',
            dueDate: DateTime(now.year, now.month, now.day, 7),
          );
      await tester.pumpAndSettle();

      expect(find.text('งานใหม่'), findsOneWidget);
    });
  });
}
