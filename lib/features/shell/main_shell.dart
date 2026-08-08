import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/motion/motion.dart';
import '../calendar/calendar_screen.dart';
import '../chat/chat_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/widgets/bottom_nav_bar.dart';
import '../news/news_screen.dart';
import '../tasks/widgets/add_task_sheet.dart';

/// The app's root shell. Owns the single floating [BottomNavBar] and swaps
/// the four primary pages behind it via an [IndexedStack] (so each keeps
/// its scroll position and provider subscriptions while backgrounded).
///
/// The individual pages no longer render their own nav bar — the shell is
/// the one place it lives. The center "+" runs the same quick-add flow from
/// any tab. Weather is reached from the dashboard's weather card.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  // Drives a brief fade-through pulse each time the tab changes. The
  // IndexedStack keeps every page alive (scroll + provider state), so we
  // animate the reveal rather than cross-fading two live trees.
  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );

  static const _pages = <Widget>[
    DashboardScreen(),
    CalendarScreen(),
    NewsScreen(),
    ChatScreen(),
  ];

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
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
    return Scaffold(
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
              child: IndexedStack(index: _index, children: _pages),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: _index,
              onTap: _select,
              onAdd: () => openAddTask(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
