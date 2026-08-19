import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/kairos_spinner.dart';
import 'models/chat_message.dart';
import 'providers/chat_provider.dart';

/// The assistant, as an actual conversation.
///
/// What this replaces was a single-line command box on the dashboard: you
/// typed, one grey line appeared, and it was gone the moment you typed again.
/// Three things made it hard to use, and each one is answered here.
///
/// 1. **Nobody knew what to type.** One example lived in the hint text. The
///    empty state now offers real prompts you can tap.
/// 2. **Nothing persisted.** Replies vanished, so there was no way to check
///    what the assistant had said it did. The transcript is kept on device.
/// 3. **Actions were invisible.** "created a task" was the same grey line as
///    everything else. A created task now renders as a card you can undo.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _controller.text.trim().isNotEmpty && !ref.read(chatProvider).sending;

  Future<void> _send([String? preset]) async {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    _scrollToEnd();

    await ref.read(chatProvider.notifier).send(text);
    _scrollToEnd();
  }

  /// Runs after the frame so the new bubble is laid out before we scroll to
  /// it — scrolling to `maxScrollExtent` in the same frame lands short.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (AppMotion.reduced(context)) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('ผู้ช่วย Kairos'),
        actions: [
          if (!chat.isEmpty)
            IconButton(
              tooltip: 'ล้างบทสนทนา',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.isEmpty
                ? _EmptyState(onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    // Dragging the transcript puts the keyboard away — reading
                    // back is the commonest reason to scroll mid-conversation.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.screenPadding,
                      DesignTokens.space4,
                      DesignTokens.screenPadding,
                      DesignTokens.space4,
                    ),
                    itemCount: chat.messages.length + (chat.sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= chat.messages.length) return const _Typing();
                      return _Bubble(message: chat.messages[i]);
                    },
                  ),
          ),
          _Composer(
            controller: _controller,
            canSend: _canSend,
            sending: chat.sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ล้างบทสนทนา?'),
        content: const Text(
          'ข้อความทั้งหมดจะถูกลบ งานที่สร้างไว้แล้วจะยังอยู่',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ล้าง'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) ref.read(chatProvider.notifier).clear();
  }
}

/// The first screen anyone sees, and the fix for "what do I even type here".
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});

  final ValueChanged<String> onPick;

  /// Real, tappable examples — one per thing the assistant can actually do,
  /// so the empty state doubles as the feature list.
  static const _prompts = <({IconData icon, String text})>[
    (icon: Icons.event_rounded, text: 'พรุ่งนี้ 9 โมงเช้าประชุมทีม'),
    (icon: Icons.checklist_rounded, text: 'เย็นนี้ต้องส่งรายงานให้ลูกค้า'),
    (icon: Icons.wb_sunny_rounded, text: 'วันนี้อากาศเป็นยังไง'),
    (icon: Icons.show_chart_rounded, text: 'สรุปข่าวเทคโนโลยีให้หน่อย'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenPadding,
        DesignTokens.space8,
        DesignTokens.screenPadding,
        DesignTokens.space6,
      ),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: palette.heroGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: palette.onHero, size: 28),
          ),
        ),
        const SizedBox(height: DesignTokens.space5),
        Text(
          'ให้ช่วยอะไรดี?',
          textAlign: TextAlign.center,
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'พิมพ์เป็นภาษาพูดได้เลย ถ้าเป็นงานที่ต้องทำ\nจะเพิ่มเข้าปฏิทินให้อัตโนมัติ',
          textAlign: TextAlign.center,
          style: context.text.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: DesignTokens.space6),
        for (final prompt in _prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space3),
            child: _PromptChip(
              icon: prompt.icon,
              text: prompt.text,
              onTap: () => onPick(prompt.text),
            ),
          ),
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Semantics(
      button: true,
      label: text,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(text, style: context.text.bodyMedium),
              ),
              Icon(Icons.arrow_outward_rounded, size: 16, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final palette = context.palette;
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            // Bubbles stop short of the far edge so the direction of the
            // conversation stays readable at a glance.
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? cs.primary
                    : message.failed
                        ? cs.errorContainer
                        : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(DesignTokens.radiusXl),
                  topRight: const Radius.circular(DesignTokens.radiusXl),
                  bottomLeft: Radius.circular(
                      isUser ? DesignTokens.radiusXl : DesignTokens.radiusSm),
                  bottomRight: Radius.circular(
                      isUser ? DesignTokens.radiusSm : DesignTokens.radiusXl),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: message.failed
                            ? Colors.transparent
                            : cs.outlineVariant,
                      ),
              ),
              child: Text(
                message.text,
                style: context.text.bodyLarge?.copyWith(
                  color: isUser
                      ? cs.onPrimary
                      : message.failed
                          ? cs.onErrorContainer
                          : cs.onSurface,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (message.createdTask) ...[
            const SizedBox(height: DesignTokens.space2),
            _TaskCard(
              name: message.createdTaskName ?? '',
              due: message.createdTaskDue,
              onUndo: () =>
                  ref.read(chatProvider.notifier).undoTaskFromMessage(message.id),
            ),
          ],
          if (message.failed) ...[
            const SizedBox(height: 4),
            Text(
              'ตรวจสอบการเชื่อมต่อ หรือคีย์ OpenRouter ใน .env',
              style: context.text.bodySmall
                  ?.copyWith(color: palette.onHeroVariant.withValues(alpha: 1)),
            ),
          ],
        ],
      ),
    );
  }
}

/// The visible result of an action, so "I made you a task" is something you
/// can see and reverse rather than a sentence you have to trust.
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.name,
    required this.due,
    required this.onUndo,
  });

  final String name;
  final DateTime? due;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color: palette.successContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 20, color: palette.onSuccessContainer),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall
                      ?.copyWith(color: palette.onSuccessContainer),
                ),
                if (due != null)
                  Text(
                    DateFormat('d MMM · HH:mm').format(due!),
                    style: context.text.bodySmall?.copyWith(
                      color: palette.onSuccessContainer.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          TextButton(
            onPressed: onUndo,
            style: TextButton.styleFrom(
              foregroundColor: palette.onSuccessContainer,
              minimumSize: const Size(48, DesignTokens.minTouchTarget),
            ),
            child: const Text('เลิกทำ'),
          ),
        ],
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: const KairosSpinner(size: 18, strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.canSend,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space4,
            DesignTokens.space2,
            DesignTokens.space2,
            DesignTokens.space2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  // Grows with the message but stops before it eats the
                  // transcript on a phone.
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => canSend ? onSend() : null,
                  decoration: const InputDecoration(
                    hintText: 'พิมพ์ข้อความ...',
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: IconButton.filled(
                  onPressed: canSend ? onSend : null,
                  iconSize: 20,
                  // 48px so a thumb can hit it without aiming.
                  constraints: const BoxConstraints(
                    minWidth: DesignTokens.minTouchTarget,
                    minHeight: DesignTokens.minTouchTarget,
                  ),
                  icon: sending
                      ? KairosSpinner(
                          size: 18,
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
