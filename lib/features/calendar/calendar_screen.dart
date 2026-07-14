import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';

/// Timeline / calendar page — the second screen of the
/// `homepage_and_calender` reference. A light "Today" header with a
/// horizontal date strip and a vertical timeline of the day's items.
///
/// The homepage half of that mockup is already implemented by
/// [DashboardScreen], so this page delivers the calendar half. It's the
/// screen behind the bottom nav's "docs" tab (index 1).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// Seven days centered on the selected one. Real data would come from a
  /// calendar provider; kept local so the screen is explorable standalone.
  late final List<DateTime> _days;
  int _selected = 3; // "today" sits 4th in the strip, matching the mockup

  static const _timeline = <_TimelineEntry>[
    _TimelineEntry(
      title: 'Meeting',
      time: '9.00 AM',
      subtitle: 'Discuss team task for the day',
      featured: true,
      attendees: 3,
    ),
    _TimelineEntry(title: 'Icon set', time: '9.00 AM', subtitle: 'Edit icons for team task for next week'),
    _TimelineEntry(title: 'Prototype', time: '9.00 AM', subtitle: 'Make and send prototype to the client'),
    _TimelineEntry(title: 'Check asset', time: '9.00 AM', subtitle: 'Start checking asset'),
  ];

  @override
  void initState() {
    super.initState();
    final base = DateTime.now();
    _days = List.generate(7, (i) => DateTime(base.year, base.month, base.day + (i - _selected)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _days[_selected];
    return Scaffold(
      backgroundColor: DesignTokens.cardWhite,
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
            child: ListView.builder(
              // Bottom padding clears the shell's floating nav bar.
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
              itemCount: _timeline.length,
              itemBuilder: (context, i) => _TimelineRow(
                entry: _timeline[i],
                isFirst: i == 0,
                isLast: i == _timeline.length - 1,
              ),
            ),
          ),
        ],
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
                  style: const TextStyle(fontSize: 13, color: DesignTokens.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeLabel(date),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textStrong,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.secondaryCard,
              shape: BoxShape.circle,
              border: Border.all(color: DesignTokens.hairline),
            ),
            child: const Icon(Icons.person_rounded, size: 22, color: DesignTokens.textMuted),
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
          return GestureDetector(
            onTap: () => onSelect(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 52 : 40,
              decoration: BoxDecoration(
                color: active ? DesignTokens.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(26),
                boxShadow: active
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(d),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? Colors.white : DesignTokens.textFaint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('E').format(d).substring(0, 3),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: active ? Colors.white : DesignTokens.textFaint,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Timeline --------------------------------------------------------------

class _TimelineEntry {
  const _TimelineEntry({
    required this.title,
    required this.time,
    required this.subtitle,
    this.featured = false,
    this.attendees = 0,
  });

  final String title;
  final String time;
  final String subtitle;
  final bool featured;
  final int attendees;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isFirst, required this.isLast});

  final _TimelineEntry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
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
                    color: entry.featured ? DesignTokens.secondaryCard : DesignTokens.cardWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: entry.featured ? DesignTokens.brand : DesignTokens.hairline,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: DesignTokens.hairline),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28, top: 2),
              child: entry.featured ? _FeaturedCard(entry: entry) : _PlainItem(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.entry});
  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DesignTokens.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text(entry.time, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AvatarStack(count: entry.attendees),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check, size: 16, color: DesignTokens.brand),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
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
                  color: DesignTokens.textMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: DesignTokens.brandViolet, width: 2),
                ),
                child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlainItem extends StatelessWidget {
  const _PlainItem({required this.entry});
  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(entry.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: DesignTokens.textStrong)),
            Text(entry.time, style: const TextStyle(fontSize: 12, color: DesignTokens.textFaint)),
          ],
        ),
        const SizedBox(height: 4),
        Text(entry.subtitle,
            style: const TextStyle(fontSize: 13, color: DesignTokens.textFaint, height: 1.3)),
      ],
    );
  }
}
