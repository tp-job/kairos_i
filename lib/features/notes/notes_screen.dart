import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'models/note_model.dart';
import 'note_form_screen.dart';
import 'providers/notes_provider.dart';

/// The notes list — a two-column masonry of tinted cards. Pure local state via
/// [notesProvider]; creating and editing both happen on [NoteFormScreen].
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _query = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    final filtered = _search.trim().isEmpty
        ? notes
        : notes
            .where((n) =>
                n.title.toLowerCase().contains(_search.toLowerCase()) ||
                n.body.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final pinned = filtered.where((n) => n.pinned).toList();
    final others = filtered.where((n) => !n.pinned).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NoteFormScreen()),
        ),
        tooltip: 'เขียนโน้ตใหม่',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(count: notes.length)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  DesignTokens.screenPadding, 4, DesignTokens.screenPadding, 8),
              sliver: SliverToBoxAdapter(
                child: _SearchField(
                  controller: _query,
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(searching: _search.isNotEmpty),
              )
            else ...[
              if (pinned.isNotEmpty) ...[
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      DesignTokens.screenPadding, 8, DesignTokens.screenPadding, 8),
                  sliver: SliverToBoxAdapter(child: _SectionLabel(text: 'ปักหมุด')),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: _NoteGrid(notes: pinned),
                ),
              ],
              if (others.isNotEmpty) ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(DesignTokens.screenPadding,
                      pinned.isNotEmpty ? 16 : 8, DesignTokens.screenPadding, 8),
                  sliver: SliverToBoxAdapter(
                    child: _SectionLabel(
                      text: pinned.isNotEmpty ? 'อื่นๆ' : 'โน้ตทั้งหมด',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: _NoteGrid(notes: others),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: DesignTokens.navBarClearance),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.screenPadding, 8, DesignTokens.screenPadding, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('โน้ต', style: context.text.displayMedium),
              const SizedBox(height: 4),
              Text(
                '$count รายการ',
                style: context.text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_note_rounded,
                color: scheme.onPrimaryContainer, size: 22),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ค้นหาโน้ต',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'ล้างคำค้นหา',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.labelMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// A simple two-column masonry: notes alternate left/right so cards of
/// differing heights pack tightly without a staggered-grid dependency.
class _NoteGrid extends StatelessWidget {
  const _NoteGrid({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final left = <Note>[];
    final right = <Note>[];
    for (var i = 0; i < notes.length; i++) {
      (i.isEven ? left : right).add(notes[i]);
    }
    return SliverToBoxAdapter(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (final n in left)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space3),
                    child: _NoteCard(note: n),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              children: [
                for (final n in right)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space3),
                    child: _NoteCard(note: n),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final tint = palette.noteTint(note.colorIndex);
    final ink = palette.onNote;

    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NoteFormScreen(note: note)),
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(color: ink),
                  ),
                ),
                Semantics(
                  button: true,
                  label: note.pinned ? 'เลิกปักหมุด' : 'ปักหมุด',
                  child: PressableScale(
                    onTap: () =>
                        ref.read(notesProvider.notifier).togglePin(note.id),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        note.pinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        size: 16,
                        color: ink.withValues(alpha: note.pinned ? 0.9 : 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (note.body.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space2),
              Text(
                note.body,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall
                    ?.copyWith(color: ink.withValues(alpha: 0.8), height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off_rounded : Icons.note_alt_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              searching ? 'ไม่พบโน้ตที่ค้นหา' : 'ยังไม่มีโน้ต',
              style: context.text.titleMedium,
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              searching
                  ? 'ลองคำค้นหาอื่น'
                  : 'แตะปุ่ม + ด้านล่างเพื่อเริ่มเขียนโน้ตแรกของคุณ',
              textAlign: TextAlign.center,
              style: context.text.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
