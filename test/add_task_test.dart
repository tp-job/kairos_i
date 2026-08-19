// Tests for the local (no-API) add-task feature: the store creates,
// filters, completes and *persists* tasks, and the "+" sheet drives the same
// store end to end — all without ClickUp credentials or a network.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/features/calendar/calendar_screen.dart';
import 'package:kairos_i/features/tasks/providers/tasks_provider.dart';
import 'package:kairos_i/features/tasks/widgets/add_task_sheet.dart';

import 'support/prefs_harness.dart';

Widget _wrap(Widget child) => ProviderScope(
      overrides: prefsOverrides,
      child: MaterialApp(home: child),
    );

ProviderContainer _container() {
  final container = ProviderContainer(overrides: prefsOverrides);
  addTearDown(container.dispose);
  return container;
}

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
  // A fresh in-memory store per test. The task list starts genuinely empty —
  // the four fake seed tasks the app used to ship were removed so a new user
  // sees an honest empty state rather than items they never created.
  setUp(() => initPrefs());

  group('LocalTasksNotifier', () {
    test('starts empty on a first launch', () {
      expect(_container().read(localTasksProvider), isEmpty);
    });

    test('add() creates a task and keeps the list sorted by due date', () {
      final container = _container();
      final notifier = container.read(localTasksProvider.notifier);

      final now = DateTime.now();
      DateTime at(int hour) => DateTime(now.year, now.month, now.day, hour);

      notifier.add(name: 'Late review', dueDate: at(16));
      notifier.add(name: 'Early standup', dueDate: at(8));

      final tasks = container.read(localTasksProvider);
      expect(tasks.map((t) => t.name), ['Early standup', 'Late review']);
      expect(tasks.first.done, isFalse);
    });

    test('undated tasks sort last', () {
      final container = _container();
      final notifier = container.read(localTasksProvider.notifier);

      notifier.add(name: 'Someday');
      notifier.add(name: 'Dated', dueDate: DateTime.now());

      expect(container.read(localTasksProvider).last.name, 'Someday');
    });

    test('toggleDone flips done and status both ways', () {
      final container = _container();
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
      final container = _container();
      final notifier = container.read(localTasksProvider.notifier);

      notifier.add(name: 'Keep', dueDate: DateTime.now());
      final task = notifier.add(name: 'Temp', dueDate: DateTime.now());

      notifier.delete(task.id);

      final after = container.read(localTasksProvider);
      expect(after.map((t) => t.name), ['Keep']);
    });
  });

  // The bug this locks: the store was in-memory, so every task a user typed
  // was silently discarded the next time the app launched.
  group('persistence', () {
    test('tasks survive a restart', () {
      final first = _container();
      final due = DateTime.now().add(const Duration(hours: 2));
      first.read(localTasksProvider.notifier).add(
            name: 'ส่งรายงาน',
            description: 'ฉบับเต็ม',
            dueDate: due,
          );

      // A second container over the same store stands in for a cold start.
      final restarted = _container();
      final restored = restarted.read(localTasksProvider);

      expect(restored.length, 1);
      expect(restored.single.name, 'ส่งรายงาน');
      expect(restored.single.description, 'ฉบับเต็ม');
      expect(restored.single.dueDate!.millisecondsSinceEpoch,
          due.millisecondsSinceEpoch);
    });

    test('completing a task survives a restart', () {
      final first = _container();
      final task = first
          .read(localTasksProvider.notifier)
          .add(name: 'Ship', dueDate: DateTime.now());
      first.read(localTasksProvider.notifier).toggleDone(task.id);

      expect(_container().read(localTasksProvider).single.done, isTrue);
    });

    test('deletion survives a restart', () {
      final first = _container();
      final notifier = first.read(localTasksProvider.notifier);
      notifier.add(name: 'Keep', dueDate: DateTime.now());
      final doomed = notifier.add(name: 'Gone', dueDate: DateTime.now());
      notifier.delete(doomed.id);

      expect(_container().read(localTasksProvider).map((t) => t.name), ['Keep']);
    });

    test('a corrupt payload is discarded instead of blocking launch',
        () async {
      // Anything that is not the expected JSON list — a half-written file, a
      // payload from an older shape. Throwing here would brick every cold
      // start permanently, which is far worse than losing the list once.
      await initPrefs({'kairos.tasks.v1': 'not json at all'});

      expect(_container().read(localTasksProvider), isEmpty);
    });
  });

  group('tasksForDayProvider', () {
    test('returns only tasks due on the given day', () {
      final container = _container();

      final today = DateTime.now();
      final nextWeek = today.add(const Duration(days: 7));
      final notifier = container.read(localTasksProvider.notifier);
      notifier.add(name: 'Today thing', dueDate: today);
      notifier.add(name: 'Next week thing', dueDate: nextWeek);

      expect(
        container.read(tasksForDayProvider(today)).map((t) => t.name),
        ['Today thing'],
      );
      expect(
        container.read(tasksForDayProvider(nextWeek)).map((t) => t.name),
        ['Next week thing'],
      );
    });
  });

  group('add-task sheet', () {
    testWidgets('the sheet paints its own surface', (tester) async {
      // Regression: `backgroundColor: Colors.transparent` was set with no
      // replacement surface, so the screen behind showed straight through
      // the form and the title collided with the list underneath.
      await tester.pumpWidget(_wrap(const _SheetHost()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('เพิ่มงานใหม่'),
              matching: find.byType(Material),
            )
            .last,
      );
      expect(material.color, isNotNull);
      expect(material.color, isNot(Colors.transparent));
    });

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
    testWidgets('shows the empty state when the day has no tasks',
        (tester) async {
      await tester.pumpWidget(_wrap(const CalendarScreen()));
      await tester.pumpAndSettle();

      // No fake rows: the seed tasks are gone, so a new user's first look at
      // the timeline is an honest empty day.
      expect(find.text('Meeting'), findsNothing);
      expect(find.text('Check asset'), findsNothing);
    });

    testWidgets('a newly added task appears on the timeline', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarScreen()));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarScreen)),
      );
      final now = DateTime.now();
      container.read(localTasksProvider.notifier).add(
            name: 'งานใหม่',
            dueDate: DateTime(now.year, now.month, now.day, 7),
          );
      await tester.pumpAndSettle();

      expect(find.text('งานใหม่'), findsOneWidget);
    });
  });
}
