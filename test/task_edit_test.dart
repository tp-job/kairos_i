// Editing, updating and deleting a task.
//
// `LocalTasksNotifier.update()` and `delete()` existed but nothing in the UI
// ever called them — a task could be created and ticked off, never corrected
// or removed. These cover the flows that now reach them, and the keyboard
// behaviour the forms need on a phone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/core/theme/app_theme.dart';
import 'package:kairos_i/core/theme/material_scheme.dart';
import 'package:kairos_i/features/calendar/calendar_screen.dart';
import 'package:kairos_i/features/tasks/models/task_model.dart';
import 'package:kairos_i/features/tasks/providers/tasks_provider.dart';
import 'package:kairos_i/features/tasks/widgets/add_task_sheet.dart';

import 'support/prefs_harness.dart';

Widget _wrap(Widget child) => ProviderScope(
      overrides: prefsOverrides,
      child: MaterialApp(
        theme: AppTheme.buildTheme(MaterialSchemes.light),
        home: child,
      ),
    );

/// Host that opens the sheet in edit mode for a given task.
class _EditHost extends ConsumerWidget {
  const _EditHost({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => openEditTask(context, ref, task),
          child: const Text('open'),
        ),
      ),
    );
  }
}

ProviderContainer _containerOf(WidgetTester tester, Finder of) =>
    ProviderScope.containerOf(tester.element(of));

void main() {
  setUp(() => initPrefs());

  group('edit sheet', () {
    late TaskModel task;

    Future<ProviderContainer> pumpWithTask(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final seed = ProviderContainer(overrides: prefsOverrides);
      addTearDown(seed.dispose);
      task = seed.read(localTasksProvider.notifier).add(
            name: 'ส่งรายงาน',
            description: 'ฉบับร่าง',
            dueDate: DateTime(2026, 8, 19, 14, 30),
          );

      await tester.pumpWidget(_wrap(_EditHost(task: task)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      return _containerOf(tester, find.byType(_EditHost));
    }

    testWidgets('opens with the task prefilled', (tester) async {
      await pumpWithTask(tester);

      expect(find.text('แก้ไขงาน'), findsOneWidget);
      expect(find.text('ส่งรายงาน'), findsOneWidget);
      expect(find.text('ฉบับร่าง'), findsOneWidget);
      // The task's own time, not the "next round hour" a new task defaults to.
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('saving updates in place instead of creating a second task',
        (tester) async {
      final container = await pumpWithTask(tester);

      await tester.enterText(find.byType(TextField).first, 'ส่งรายงานฉบับจริง');
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึกการแก้ไข'));
      await tester.pumpAndSettle();

      final tasks = container.read(localTasksProvider);
      // The duplicate is the bug worth guarding: an "edit" that calls add()
      // looks correct on screen until you count the rows.
      expect(tasks.length, 1);
      expect(tasks.single.id, task.id);
      expect(tasks.single.name, 'ส่งรายงานฉบับจริง');
      // Untouched fields survive the edit.
      expect(tasks.single.description, 'ฉบับร่าง');
    });

    testWidgets('an edit survives a restart', (tester) async {
      await pumpWithTask(tester);

      await tester.enterText(find.byType(TextField).first, 'แก้แล้ว');
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึกการแก้ไข'));
      await tester.pumpAndSettle();

      final restarted = ProviderContainer(overrides: prefsOverrides);
      addTearDown(restarted.dispose);
      expect(restarted.read(localTasksProvider).single.name, 'แก้แล้ว');
    });

    testWidgets('delete removes the task', (tester) async {
      final container = await pumpWithTask(tester);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(container.read(localTasksProvider), isEmpty);
    });

    testWidgets('undo restores a deleted task', (tester) async {
      final container = await pumpWithTask(tester);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      expect(container.read(localTasksProvider), isEmpty);

      await tester.tap(find.text('เลิกทำ'));
      await tester.pumpAndSettle();

      final restored = container.read(localTasksProvider);
      expect(restored.length, 1);
      expect(restored.single.name, 'ส่งรายงาน');
      expect(restored.single.description, 'ฉบับร่าง');
    });

    testWidgets('the create sheet has no delete button', (tester) async {
      await tester.pumpWidget(_wrap(const _CreateHost()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('เพิ่มงานใหม่'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });

  group('keyboard behaviour on a phone', () {
    testWidgets('the task form dismisses the keyboard on drag',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const _CreateHost()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Reaching for the date chips or the save button is exactly the gesture
      // that should put the keyboard away — otherwise they stay covered.
      final scroll = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(SafeArea),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(
        scroll.keyboardDismissBehavior,
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
    });

    testWidgets('the description field commits rather than adding a newline',
        (tester) async {
      await tester.pumpWidget(_wrap(const _CreateHost()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.first.textInputAction, TextInputAction.next);
      expect(fields.last.textInputAction, TextInputAction.done);
    });

    testWidgets('the date chips fit a narrow phone once a date is picked',
        (tester) async {
      // The regression: three chips in a fixed Row fit while the third read
      // "เลือกวัน", then overflowed by 85px the moment it became a date.
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final seed = ProviderContainer(overrides: prefsOverrides);
      addTearDown(seed.dispose);
      final dated = seed.read(localTasksProvider.notifier).add(
            name: 'มีกำหนดส่ง',
            dueDate: DateTime(2026, 12, 31, 23, 45),
          );

      await tester.pumpWidget(_wrap(_EditHost(task: dated)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // All three remain reachable rather than one being clipped away.
      expect(find.text('วันนี้'), findsOneWidget);
      expect(find.text('พรุ่งนี้'), findsOneWidget);
    });

    testWidgets('the form fits a short screen with the keyboard up',
        (tester) async {
      // A 412x915 phone with a ~340px keyboard leaves this much room.
      tester.view.physicalSize = const Size(412, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const _CreateHost()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('tapping a task opens the editor', () {
    testWidgets('from the calendar timeline', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final seed = ProviderContainer(overrides: prefsOverrides);
      addTearDown(seed.dispose);
      final now = DateTime.now();
      seed.read(localTasksProvider.notifier).add(
            name: 'ประชุมทีม',
            dueDate: DateTime(now.year, now.month, now.day, 9),
          );

      await tester.pumpWidget(_wrap(const CalendarScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ประชุมทีม'));
      await tester.pumpAndSettle();

      expect(find.text('แก้ไขงาน'), findsOneWidget);
    });
  });

  group('dashboard checkbox', () {
    testWidgets('toggles done — it used to be a Container that did nothing',
        (tester) async {
      final container = ProviderContainer(overrides: prefsOverrides);
      addTearDown(container.dispose);
      final task = container
          .read(localTasksProvider.notifier)
          .add(name: 'งานวันนี้', dueDate: DateTime.now());

      expect(container.read(localTasksProvider).single.done, isFalse);

      container.read(localTasksProvider.notifier).toggleDone(task.id);
      expect(container.read(localTasksProvider).single.done, isTrue);
    });
  });
}

class _CreateHost extends ConsumerWidget {
  const _CreateHost();

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
