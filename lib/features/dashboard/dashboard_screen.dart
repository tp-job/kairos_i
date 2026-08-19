import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/motion/motion.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../account/providers/profile_provider.dart';
import '../market/providers/market_provider.dart';
import '../news/models/news_model.dart';
import '../news/providers/news_provider.dart';
import '../notes/providers/notes_provider.dart';
import '../orchestrator/providers/chat_provider.dart';
import '../tasks/models/task_model.dart';
import '../tasks/providers/tasks_provider.dart';
import '../tasks/widgets/add_task_sheet.dart';
import '../weather/providers/weather_provider.dart';
import 'widgets/dashboard_header.dart';

/// The dashboard: a brand hero header with an overlapping search bar, a row of
/// summary cards, and the task list. Kairos's real providers feed the cards.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // No top SafeArea: the hero header bleeds under the status bar and
      // carries its own top padding. The bottom padding clears the shell's
      // floating nav bar.
      body: SingleChildScrollView(
        // The dashboard carries a search field and the AI command bar, so a
        // scroll while the keyboard is up should put it away rather than
        // leaving it covering the cards being scrolled to.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: DesignTokens.navBarClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopSection(),
            const SizedBox(height: DesignTokens.space6),
            const FadeSlideIn(
              delay: Duration(milliseconds: 80),
              child: _ProjectsSection(),
            ),
            const SizedBox(height: DesignTokens.space8),
            const FadeSlideIn(
              delay: Duration(milliseconds: 180),
              child: _TasksSection(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero header + the search bar straddling its bottom edge.
///
/// The header reserves [_overlap] px of blank space beneath it and the search
/// bar is pinned to the bottom of that space, so the bar sits half over the
/// header and half over the page while staying inside the Stack's bounds (an
/// out-of-bounds `Positioned` child drops taps on the overhang).
class _TopSection extends ConsumerWidget {
  const _TopSection();

  static const double _overlap = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: _overlap),
          child: DashboardHeader(
            // Both the time of day and the name used to be hardcoded — every
            // user was greeted as "Marimar", at any hour.
            greeting: ref.watch(greetingProvider),
            headline: 'มาเริ่มจัดการ\nงานของคุณกัน',
            initials: ref.watch(profileProvider).initials,
            onAvatar: () => context.push(Routes.account),
          ),
        ),
        const Positioned(
          left: DesignTokens.screenPadding,
          right: DesignTokens.screenPadding,
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

  /// Sends the message *and* opens the conversation.
  ///
  /// It used to fire into the orchestrator and stay put, so the reply landed
  /// nowhere the user could see — you typed, the field cleared, and that was
  /// the entire feedback. Handing off to [ChatScreen] means the fast path
  /// from the dashboard is kept, but the answer has somewhere to arrive.
  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    context.push(Routes.chat);
    ref.read(chatProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      decoration: AppTheme.softCard(context, radius: DesignTokens.radiusXl),
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      child: Row(
        children: [
          // Not a magnifying glass: nothing here searches. It opens the
          // assistant, and the icon should say so.
          Icon(Icons.auto_awesome, color: scheme.onSurfaceVariant, size: 20),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              style: context.text.bodyMedium,
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'ถามผู้ช่วย หรือสั่งเพิ่มงาน',
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'ส่งคำสั่ง',
            child: Material(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: InkWell(
                onTap: _submit,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_upward_rounded,
                      color: scheme.onPrimary, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Summary cards --------------------------------------------------------

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding:
              EdgeInsets.symmetric(horizontal: DesignTokens.screenPadding),
          child: _SectionHeader(title: 'ภาพรวม', action: 'ทั้งหมด'),
        ),
        const SizedBox(height: DesignTokens.space4),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.screenPadding),
            children: const [
              _WeatherProjectCard(),
              SizedBox(width: DesignTokens.space4),
              _MarketMiniCard(),
              SizedBox(width: DesignTokens.space4),
              _NewsMiniCard(),
              SizedBox(width: DesignTokens.space4),
              _NotesMiniCard(),
              SizedBox(width: DesignTokens.space2),
            ],
          ),
        ),
      ],
    );
  }
}

/// The one saturated card on the page — bound to live weather.
class _WeatherProjectCard extends ConsumerWidget {
  const _WeatherProjectCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final palette = context.palette;
    final scheme = context.colors;

    return PressableScale(
      // Shared-axis Z: the card the finger just pressed opens *deeper*, not
      // sideways. Transition lives with the route (core/navigation).
      onTap: () => context.push(Routes.weather),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(DesignTokens.cardPadding),
        decoration: BoxDecoration(
          gradient: palette.heroGradient,
          borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.onHero.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wb_sunny_rounded,
                  color: palette.onHero, size: 20),
            ),
            const SizedBox(height: DesignTokens.space5),
            Text(
              'สภาพอากาศ',
              style: context.text.titleMedium?.copyWith(color: palette.onHero),
            ),
            const SizedBox(height: DesignTokens.space1),
            Expanded(
              child: weather.when(
                data: (data) => Text(
                  '${data.cityName} · ${data.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall
                      ?.copyWith(color: palette.onHeroVariant),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => Text(
                  'ตั้งค่า API key เพื่อดูข้อมูล',
                  style: context.text.bodySmall
                      ?.copyWith(color: palette.onHeroVariant),
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
                      style: context.text.displayMedium?.copyWith(
                        color: palette.onHero,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.onHero,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right,
                      color: scheme.primary, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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

class _NotesMiniCard extends ConsumerWidget {
  const _NotesMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final subtitle = notes.isEmpty ? 'เริ่มเขียนโน้ตแรก' : notes.first.title;
    return _MiniCard(
      icon: Icons.edit_note_rounded,
      title: 'โน้ต',
      subtitle: subtitle,
      // Notes is a primary tab now, not a pushed page — switch branches so the
      // nav bar stays honest about where the user is.
      onTap: () => context.go(Routes.notes),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final card = Container(
      width: 160,
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: AppTheme.sunkenCard(context,
          radius: DesignTokens.radius2xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          const SizedBox(height: DesignTokens.space5),
          Text(title, style: context.text.titleSmall),
          const SizedBox(height: DesignTokens.space1),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
    return onTap == null ? card : PressableScale(onTap: onTap, child: card);
  }
}

// --- Tasks ----------------------------------------------------------------

class _TasksSection extends ConsumerWidget {
  const _TasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reads the local store, not ClickUp: this section must show the task you
    // just added via "+" whether or not the API is configured.
    final items = ref.watch(upcomingLocalTasksProvider);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: DesignTokens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'งานของฉัน', action: 'ดูทั้งหมด'),
          const SizedBox(height: DesignTokens.space4),
          if (items.isEmpty)
            const _TaskPlaceholder(text: 'ไม่มีงานค้าง 🎉 แตะ + เพื่อเพิ่มงาน')
          else
            Column(
              children: [
                for (final task in items.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space3),
                    child: _TaskItem(task: task),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TaskItem extends ConsumerWidget {
  const _TaskItem({required this.task});

  final TaskModel task;

  bool get _done {
    final s = task.status.toLowerCase();
    return s.contains('complete') || s.contains('done') || s.contains('closed');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final due = task.dueDate;
    final subtitle =
        due != null ? DateFormat('d MMM · HH:mm').format(due) : task.status;

    return Opacity(
      opacity: _done ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: AppTheme.softCard(context),
        child: Row(
          children: [
            // The checkbox was previously a plain Container — it *looked*
            // like a control and did nothing, so a task could only be
            // completed from the calendar.
            Semantics(
              button: true,
              checked: _done,
              label: task.name,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    ref.read(localTasksProvider.notifier).toggleDone(task.id),
                // 24px of art inside a 48px target: the tick stays small
                // without asking a thumb to hit a 24px square.
                child: SizedBox(
                  width: DesignTokens.minTouchTarget,
                  height: DesignTokens.minTouchTarget,
                  child: Center(child: _CheckboxArt(done: _done)),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            Expanded(
              child: Semantics(
                button: true,
                label: 'แก้ไข ${task.name}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openEditTask(context, ref, task),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          decoration:
                              _done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
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

/// The tick itself. Presentation only — [_TaskItem] owns the gesture and the
/// hit target so the two cannot drift apart.
class _CheckboxArt extends StatelessWidget {
  const _CheckboxArt({this.done = false});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: done ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: done ? null : Border.all(color: scheme.outline, width: 2),
      ),
      child: done
          ? Icon(Icons.check, color: scheme.onPrimary, size: 14)
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
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: AppTheme.softCard(context),
      child: Text(
        text,
        style: context.text.bodyMedium
            ?.copyWith(color: context.colors.onSurfaceVariant),
      ),
    );
  }
}

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
        Text(title, style: context.text.titleLarge),
        Text(
          action,
          style: context.text.labelLarge
              ?.copyWith(color: context.colors.primary),
        ),
      ],
    );
  }
}

// --- Sheets ---------------------------------------------------------------

// The quick-capture sheet used to live here: a second free-text AI input,
// separate from the dashboard bar, which fired into the orchestrator and
// closed without showing a reply. Nothing called it any more once the shell
// FAB moved to the deterministic add-task form, and a second AI surface with
// different behaviour was the confusing half of the old flow. One
// conversation now owns every free-text request: Routes.chat.

// Theme settings used to live here as a bottom sheet. They now sit in
// `AccountScreen` (Routes.account): the sheet's height cap put the contrast
// control under the floating nav bar, and its `SegmentedButton` could not fit
// three Thai labels without overlapping them.
