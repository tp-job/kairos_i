import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../calendar/calendar_screen.dart';
import '../chat/chat_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/widgets/bottom_nav_bar.dart';
import '../news/news_screen.dart';

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

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    CalendarScreen(),
    NewsScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _index, children: _pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              onAdd: () => openQuickAdd(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
