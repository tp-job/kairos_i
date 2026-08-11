import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/motion.dart';
import '../../core/navigation/routes.dart';
import '../dashboard/widgets/bottom_nav_bar.dart';
import '../tasks/widgets/add_task_sheet.dart';

/// The app's root shell. Owns the single floating [BottomNavBar] and the
/// back-button contract; the pages themselves come from the router's
/// [StatefulNavigationShell], which keeps one `Navigator` per tab so each
/// branch holds its own stack, scroll position and provider subscriptions
/// (FR-7.1).
///
/// The pages do not render their own nav bar — the shell is the one place it
/// lives. The centre "+" runs the same quick-add flow from any tab. Weather is
/// reached from the dashboard's weather card, above this shell.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  // Drives a brief fade-through pulse each time the tab changes. The shell
  // keeps every branch alive, so we animate the reveal rather than cross-fading
  // two live trees.
  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );

  void _select(int i) {
    if (i == widget.shell.currentIndex) {
      // Tapping the active tab pops that branch back to its root — the
      // convention every tabbed app has taught users to expect.
      widget.shell.goBranch(i, initialLocation: true);
      return;
    }
    widget.shell.goBranch(i);
    _switch.forward(from: 0);
  }

  /// §2.3 of the flow map: a tab is not a history entry. Back from any
  /// non-dashboard branch root returns to the dashboard instead of exiting —
  /// only the dashboard is a true exit point.
  void _handlePop(bool didPop, Object? result) {
    if (didPop) return;
    widget.shell.goBranch(0);
    _switch.forward(from: 0);
  }

  @override
  void dispose() {
    _switch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _switch, curve: AppMotion.emphasized);

    // The bar belongs to the four destinations, not to what is pushed on top
    // of them. Anything deeper (the note editor) is a focused mode and gets
    // the full screen — the bar slides out rather than floating over a form.
    // `uri.path` and not `matchedLocation`: inside a shell builder the latter
    // is the *shell's* own match ('/notes') and stays that way when a child
    // route is pushed, so the bar would never retract.
    final location = GoRouterState.of(context).uri.path;
    final atBranchRoot = Routes.branchOrder.contains(location);

    return PopScope(
      // Two ways a pop may proceed normally: the branch has something to pop
      // (the editor), or we are already at the dashboard — the one true exit
      // point. Everything else is a non-dashboard branch root, where back
      // means "go home", not "quit".
      canPop: !atBranchRoot || widget.shell.currentIndex == 0,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        // The shell owns the canvas; the pages inside it stay transparent so
        // this is the only surface color in the stack.
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: fade,
                builder: (context, child) => Opacity(
                  opacity: 0.4 + 0.6 * fade.value,
                  child: Transform.scale(
                    scale: 0.985 + 0.015 * fade.value,
                    child: child,
                  ),
                ),
                child: widget.shell,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: !atBranchRoot,
                child: AnimatedSlide(
                  offset: atBranchRoot ? Offset.zero : const Offset(0, 1),
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  child: BottomNavBar(
                    currentIndex: widget.shell.currentIndex,
                    onTap: _select,
                    onAdd: () => openAddTask(context, ref),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
