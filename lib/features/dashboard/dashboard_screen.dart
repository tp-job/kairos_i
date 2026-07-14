import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../market/providers/market_provider.dart';
import '../news/models/news_model.dart';
import '../news/providers/news_provider.dart';
import '../orchestrator/providers/orchestrator_provider.dart';
import '../tasks/models/task_model.dart';
import '../tasks/providers/tasks_provider.dart';
import '../weather/providers/weather_provider.dart';
import '../weather/weather_glass_screen.dart';
import 'widgets/dashboard_header.dart';

/// The dashboard, rebuilt to the "Studio" project-management reference:
/// a charcoal hero header with an overlapping search bar, a horizontal
/// row of project cards, a tasks list, and a floating bottom nav with a
/// center add button. Kairos's real providers feed the cards.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      // Scrolling content. No top SafeArea: the charcoal header bleeds
      // under the status bar (it carries its own top padding). The bottom
      // padding clears the shell's floating nav bar.
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopSection(),
            const SizedBox(height: 24),
            const _ProjectsSection(),
            const SizedBox(height: 28),
            const _TasksSection(),
          ],
        ),
      ),
    );
  }
}

/// Charcoal header + the search bar that straddles its bottom edge.
///
/// The header reserves [_overlap] px of blank space beneath it (via the
/// Padding) and the search bar is pinned to the bottom of that space, so
/// the bar sits half over the charcoal and half over the page — while
/// staying fully inside the Stack's bounds (an out-of-bounds `Positioned`
/// child would drop taps on the overhanging strip).
class _TopSection extends StatelessWidget {
  const _TopSection();

  static const double _overlap = 28;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Padding(
          padding: EdgeInsets.only(bottom: _overlap),
          child: DashboardHeader(
            greeting: 'สวัสดี, Marimar 👋',
            headline: 'มาเริ่มจัดการ\nงานของคุณกัน',
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 0,
          child: _SearchBar(),
        ),
      ],
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(orchestratorControllerProvider.notifier).submit(text);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.search, color: DesignTokens.textFaint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 14,
                color: DesignTokens.textStrong,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'ค้นหา หรือพิมพ์คำสั่ง',
                hintStyle: TextStyle(color: DesignTokens.textFaint),
              ),
            ),
          ),
          Material(
            color: DesignTokens.brand,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _submit,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.tune, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Projects (horizontal cards) -----------------------------------------

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _SectionHeader(title: 'ภาพรวม', action: 'ทั้งหมด'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: const [
              _WeatherProjectCard(),
              SizedBox(width: 16),
              _MarketMiniCard(),
              SizedBox(width: 16),
              _NewsMiniCard(),
              SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

/// Primary (dark) project card — bound to live weather.
class _WeatherProjectCard extends ConsumerWidget {
  const _WeatherProjectCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WeatherGlassScreen()),
      ),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: DesignTokens.brandGradient,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wb_sunny_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(height: 20),
            const Text(
              'สภาพอากาศ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: weather.when(
                data: (data) => Text(
                  '${data.cityName} · ${data.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => Text(
                  'ตั้งค่า API key เพื่อดูข้อมูล',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: weather.maybeWhen(
                    data: (data) => Text(
                      '${data.temperatureC.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right,
                      color: DesignTokens.brand, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary (light) card — market snapshot.
class _MarketMiniCard extends ConsumerWidget {
  const _MarketMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final subtitle = market.maybeWhen(
      data: (quotes) => quotes.isEmpty
          ? 'ดูพอร์ตการลงทุน'
          : '${quotes.first.symbol} ${quotes.first.isUp ? '▲' : '▼'} '
              '${quotes.first.changePercent.abs().toStringAsFixed(1)}%',
      orElse: () => 'ดูพอร์ตการลงทุน',
    );
    return _MiniCard(
      icon: Icons.pie_chart_rounded,
      title: 'การลงทุน',
      subtitle: subtitle,
    );
  }
}

/// Secondary (light) card — latest news.
class _NewsMiniCard extends ConsumerWidget {
  const _NewsMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    final subtitle = news.maybeWhen(
      data: (List<NewsArticle> items) =>
          items.isEmpty ? 'อ่านข่าวเทคโนโลยี' : items.first.title,
      orElse: () => 'อ่านข่าวเทคโนโลยี',
    );
    return _MiniCard(
      icon: Icons.bolt_rounded,
      title: 'ข่าวสาร',
      subtitle: subtitle,
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.secondaryCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: DesignTokens.cardWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x14000000), blurRadius: 8),
              ],
            ),
            child: Icon(icon, color: DesignTokens.brand, size: 18),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: DesignTokens.textStrong,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tasks ----------------------------------------------------------------

class _TasksSection extends ConsumerWidget {
  const _TasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'งานของฉัน', action: 'ดูทั้งหมด'),
          const SizedBox(height: 16),
          tasks.when(
            data: (items) => items.isEmpty
                ? const _TaskPlaceholder(text: 'ไม่มีงานค้าง 🎉')
                : Column(
                    children: [
                      for (final task in items.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TaskItem(task: task),
                        ),
                    ],
                  ),
            loading: () => const Column(
              children: [
                _TaskSkeleton(),
                SizedBox(height: 12),
                _TaskSkeleton(),
              ],
            ),
            error: (_, _) => const _TaskPlaceholder(
              text: 'เชื่อมต่อ ClickUp เพื่อแสดงงานของคุณ',
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({required this.task});

  final TaskModel task;

  bool get _done {
    final s = task.status.toLowerCase();
    return s.contains('complete') || s.contains('done') || s.contains('closed');
  }

  @override
  Widget build(BuildContext context) {
    final due = task.dueDate;
    final subtitle = due != null
        ? DateFormat('d MMM · HH:mm').format(due)
        : task.status;

    return Opacity(
      opacity: _done ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.softCard(),
        child: Row(
          children: [
            _Checkbox(done: _done),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: DesignTokens.hairline,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: done ? DesignTokens.brand : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: done
            ? null
            : Border.all(color: DesignTokens.hairline, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _TaskPlaceholder extends StatelessWidget {
  const _TaskPlaceholder({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.softCard(),
      child: Text(
        text,
        style: const TextStyle(color: DesignTokens.textMuted, fontSize: 13),
      ),
    );
  }
}

class _TaskSkeleton extends StatelessWidget {
  const _TaskSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: AppTheme.softCard(),
    );
  }
}

// --- Shared bits ----------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textStrong,
          ),
        ),
        Text(
          action,
          style: const TextStyle(fontSize: 13, color: DesignTokens.textMuted),
        ),
      ],
    );
  }
}

/// Quick-capture sheet opened by the center "+" — routes free text through
/// the AI orchestrator (create a task, ask a question, etc.). Public so the
/// [MainShell]'s FAB can trigger it from any tab.
void openQuickAdd(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: DesignTokens.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'เพิ่มอย่างรวดเร็ว',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textStrong,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: DesignTokens.textStrong),
                      decoration: InputDecoration(
                        hintText: 'เช่น "พรุ่งนี้บ่ายโมงส่งงาน"',
                        hintStyle:
                            const TextStyle(color: DesignTokens.textFaint),
                        filled: true,
                        fillColor: DesignTokens.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty) {
                          ref
                              .read(orchestratorControllerProvider.notifier)
                              .submit(text.trim());
                        }
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: DesignTokens.brand,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        final text = controller.text.trim();
                        if (text.isNotEmpty) {
                          ref
                              .read(orchestratorControllerProvider.notifier)
                              .submit(text);
                        }
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(controller.dispose);
}
