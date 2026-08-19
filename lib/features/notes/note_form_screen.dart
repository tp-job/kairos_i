import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'models/note_model.dart';
import 'note_heroes.dart';
import 'providers/notes_provider.dart';

/// The single form used to both **create** and **update** a note — no API
/// involved, everything lands in [notesProvider]'s in-memory state. Pass
/// [note] to edit it in place; omit it to compose a new one.
class NoteFormScreen extends ConsumerStatefulWidget {
  const NoteFormScreen({super.key, this.note});

  final Note? note;

  bool get isEditing => note != null;

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late int _colorIndex;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _body = TextEditingController(text: widget.note?.body ?? '');
    _colorIndex = widget.note?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty && body.isEmpty) {
      context.pop();
      return;
    }
    final resolvedTitle = title.isEmpty ? 'ไม่มีชื่อ' : title;
    final notifier = ref.read(notesProvider.notifier);
    if (widget.isEditing) {
      notifier.update(
        widget.note!.id,
        title: resolvedTitle,
        body: body,
        colorIndex: _colorIndex,
      );
    } else {
      notifier.add(title: resolvedTitle, body: body, colorIndex: _colorIndex);
    }
    context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบโน้ตนี้?'),
        content: const Text('เมื่อลบแล้วจะไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.colors.error,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(notesProvider.notifier).delete(widget.note!.id);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = palette.noteTint(_colorIndex);
    final ink = palette.onNote;

    return Scaffold(
      // Transparent: the tint is painted by the Hero below so it can fly in
      // from the card rather than hard-cutting behind it.
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: widget.isEditing
                  ? NoteHeroes.forNote(widget.note!.id)
                  : NoteHeroes.newNote,
              // Only the tinted surface flies; the form's content fades in on
              // top of it via FadeSlideIn.
              flightShuttleBuilder: (_, _, _, _, _) => Container(
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                ),
              ),
              child: ColoredBox(color: tint),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormHeader(
                  ink: ink,
                  onBack: _save,
                  onDelete: widget.isEditing ? _delete : null,
                  onSave: _save,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    // Scrolling the note puts the keyboard away — on a phone
                    // the body field is taller than the visible area, and
                    // re-reading what you wrote is the commonest reason to
                    // scroll while the keyboard is up.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.screenPadding,
                      8,
                      DesignTokens.screenPadding,
                      // Clears the keyboard so the last lines of a long note
                      // are reachable instead of sitting behind it.
                      32 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeSlideIn(
                          child: TextField(
                            controller: _title,
                            autofocus: !widget.isEditing,
                            maxLines: null,
                            style: context.text.headlineMedium?.copyWith(
                              color: ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'หัวข้อโน้ต',
                              hintStyle: context.text.headlineMedium?.copyWith(
                                color: ink.withValues(alpha: 0.35),
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space2),
                        Text(
                          widget.isEditing
                              ? 'แก้ไขล่าสุด ${_formatTimestamp(widget.note!.updatedAt)}'
                              : 'โน้ตใหม่',
                          style: context.text.bodySmall?.copyWith(
                            color: ink.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space5),
                        TextField(
                          controller: _body,
                          minLines: 8,
                          maxLines: null,
                          style: context.text.bodyLarge?.copyWith(
                            color: ink,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: 'เขียนบันทึกของคุณที่นี่...',
                            hintStyle: context.text.bodyLarge?.copyWith(
                              color: ink.withValues(alpha: 0.35),
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          'สี',
                          style: context.text.labelLarge?.copyWith(
                            color: ink.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space3),
                        _ColorPicker(
                          selected: _colorIndex,
                          ink: ink,
                          onSelect: (i) => setState(() => _colorIndex = i),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    if (sameDay) return 'วันนี้ $hh:$mm';
    return '${dt.day}/${dt.month}/${dt.year} $hh:$mm';
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.ink,
    required this.onBack,
    required this.onSave,
    this.onDelete,
  });

  final Color ink;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'บันทึกและย้อนกลับ',
            ink: ink,
            onTap: onBack,
          ),
          Row(
            children: [
              if (onDelete != null)
                _RoundIconButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'ลบโน้ต',
                  ink: ink,
                  onTap: onDelete,
                ),
              const SizedBox(width: DesignTokens.space2),
              _RoundIconButton(
                icon: Icons.check_rounded,
                label: 'บันทึกโน้ต',
                ink: ink,
                filled: true,
                onTap: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.ink,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tint = context.palette.noteTint(0);
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: filled ? ink : ink.withValues(alpha: 0.10),
        foregroundColor: filled ? tint : ink,
        minimumSize: const Size.square(DesignTokens.minTouchTarget),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selected,
    required this.ink,
    required this.onSelect,
  });

  final int selected;
  final Color ink;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final tints = context.palette.noteTints;
    return Wrap(
      spacing: DesignTokens.space3,
      children: [
        for (var i = 0; i < tints.length; i++)
          Semantics(
            button: true,
            selected: selected == i,
            label: 'สีที่ ${i + 1}',
            child: PressableScale(
              onTap: () => onSelect(i),
              child: SizedBox(
                // 44px tap target around a 32px swatch.
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tints[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected == i
                            ? ink
                            : ink.withValues(alpha: 0.25),
                        width: selected == i ? 2.5 : 1,
                      ),
                    ),
                    child: selected == i
                        ? Icon(Icons.check, size: 16, color: ink)
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
