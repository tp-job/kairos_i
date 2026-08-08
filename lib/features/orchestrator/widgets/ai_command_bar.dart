import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/orchestrator_models.dart';
import '../providers/orchestrator_provider.dart';

/// The single text input for the whole app — this is Feature 1 made
/// tangible: one box, no mode switcher, the AI figures out the role
/// and the action from plain text.
class AiCommandBar extends ConsumerStatefulWidget {
  const AiCommandBar({super.key});

  @override
  ConsumerState<AiCommandBar> createState() => _AiCommandBarState();
}

class _AiCommandBarState extends ConsumerState<AiCommandBar> {
  final _controller = TextEditingController();

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(orchestratorControllerProvider.notifier).submit(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(orchestratorControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          borderRadius: DesignTokens.radiusFull, // pill shape, per spec
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 18, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _handleSubmit(),
                  decoration: const InputDecoration(
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'พิมพ์อะไรก็ได้ เช่น "พรุ่งนี้บ่ายโมงมีนัดส่งงาน"',
                  ),
                ),
              ),
              result.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded),
                      color: context.colors.primary,
                      onPressed: _handleSubmit,
                    ),
            ],
          ),
        ),
        result.maybeWhen(
          data: (intent) => intent == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16),
                  child: _IntentEcho(intent: intent),
                ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _IntentEcho extends StatelessWidget {
  const _IntentEcho({required this.intent});

  final ParsedIntent intent;

  @override
  Widget build(BuildContext context) {
    final text = switch (intent.action) {
      'create_task' => '✅ สร้างงาน "${intent.taskName}" แล้ว (${intent.role.thaiLabel})',
      'answer_question' => intent.replyText ?? '',
      _ => 'รับทราบ (${intent.role.thaiLabel})',
    };
    return Text(
      text,
      style: context.text.bodySmall
          ?.copyWith(color: context.colors.onSurfaceVariant),
    );
  }
}
