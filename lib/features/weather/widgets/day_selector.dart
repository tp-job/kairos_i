import 'package:flutter/material.dart';
import '../models/weather_condition.dart';

/// One day in the bottom day-selector strip.
class DayEntry {
  const DayEntry({
    required this.label,
    required this.icon,
    required this.condition,
  });

  final String label; // "now", "tue", "wed", ...
  final IconData icon;

  /// Which illustration/palette to show if this day is selected.
  /// Weather forecast API wiring can be added later; for now this is
  /// hand-fed by whoever renders the screen.
  final WeatherCondition condition;
}

class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    required this.palette,
  });

  final List<DayEntry> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final WeatherPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < days.length; i++)
          _DayItem(
            entry: days[i],
            selected: i == selectedIndex,
            palette: palette,
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

class _DayItem extends StatelessWidget {
  const _DayItem({
    required this.entry,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final DayEntry entry;
  final bool selected;
  final WeatherPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selected pill uses a warm cream chip in the reference — approximate
    // with a low-opacity accent that reads on both light and dark palettes.
    final pillColor = palette.accent.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(entry.icon, size: 20, color: palette.ink),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? pillColor : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.label,
              style: TextStyle(
                color: selected ? palette.accent : palette.mutedInk,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
