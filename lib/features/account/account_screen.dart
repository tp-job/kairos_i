import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import 'models/user_profile.dart';
import 'providers/profile_provider.dart';

/// Account and app settings.
///
/// This replaces the theme bottom sheet. The sheet held two three-option
/// controls whose Thai labels ("มาตรฐาน / ชัดขึ้น / ชัดสูงสุด") were wider
/// than a `SegmentedButton` could give them, so they overlapped and clipped —
/// and the sheet's own height cap put the last control under the floating
/// nav bar. Neither is a styling problem: a settings surface with two
/// multi-option controls and a profile on it is a screen, not a sheet.
///
/// Options are laid out as full-width rows rather than segments, which is why
/// the overflow cannot come back — a longer label wraps into its own row
/// instead of competing for a third of the width.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final theme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('บัญชีและการตั้งค่า'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.screenPadding,
          DesignTokens.space2,
          DesignTokens.screenPadding,
          DesignTokens.space10,
        ),
        children: [
          _ProfileCard(profile: profile),
          const SizedBox(height: DesignTokens.space6),

          const _SectionLabel('โหมดสี'),
          const SizedBox(height: DesignTokens.space2),
          _OptionGroup(
            children: [
              for (final mode in ThemeMode.values)
                _OptionRow(
                  label: mode.thaiLabel,
                  description: _modeDescription(mode),
                  icon: _modeIcon(mode),
                  selected: theme.mode == mode,
                  onTap: () => themeNotifier.setMode(mode),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.space6),

          const _SectionLabel('ความคมชัด'),
          const SizedBox(height: DesignTokens.space2),
          _OptionGroup(
            children: [
              for (final contrast in AppContrast.values)
                _OptionRow(
                  label: contrast.thaiLabel,
                  description: _contrastDescription(contrast),
                  selected: theme.contrast == contrast,
                  onTap: () => themeNotifier.setContrast(contrast),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.space6),

          const _SectionLabel('เกี่ยวกับ'),
          const SizedBox(height: DesignTokens.space2),
          const _OptionGroup(
            children: [
              _InfoRow(label: 'เวอร์ชัน', value: '1.0.0'),
              _InfoRow(label: 'ข้อมูลของคุณ', value: 'เก็บในเครื่องเท่านั้น'),
            ],
          ),
        ],
      ),
    );
  }

  static String _modeDescription(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'สลับสว่าง/มืดตามการตั้งค่าของเครื่อง',
        ThemeMode.light => 'พื้นครีมอ่อน ตัวอักษรเข้ม',
        ThemeMode.dark => 'พื้นเข้ม ถนอมสายตาในที่มืด',
      };

  static IconData _modeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      };

  static String _contrastDescription(AppContrast contrast) =>
      switch (contrast) {
        AppContrast.standard => 'สมดุลระหว่างความสวยงามและการอ่าน',
        AppContrast.medium => 'เพิ่มความต่างของสีให้อ่านง่ายขึ้น',
        AppContrast.high => 'ความต่างสูงสุด สำหรับผู้ที่มองเห็นได้ยาก',
      };
}

/// Name + email, with the avatar the dashboard header mirrors.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPadding),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.onHero.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.onHero.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: profile.hasName
                    ? Text(
                        profile.initials,
                        style: context.text.titleLarge
                            ?.copyWith(color: palette.onHero),
                      )
                    : Icon(Icons.person_rounded,
                        color: palette.onHero, size: 26),
              ),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.hasName ? profile.displayName : 'ยังไม่ได้ตั้งชื่อ',
                      style: context.text.titleMedium
                          ?.copyWith(color: palette.onHero),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email.isEmpty ? 'ไม่มีอีเมล' : profile.email,
                      style: context.text.bodySmall
                          ?.copyWith(color: palette.onHeroVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: 'แก้ไขโปรไฟล์',
                  icon: Icons.edit_rounded,
                  onTap: () => _editProfile(context, ref, profile),
                ),
              ),
              if (profile.hasName || profile.email.isNotEmpty) ...[
                const SizedBox(width: DesignTokens.space2),
                _HeroButton(
                  label: 'ล้าง',
                  icon: Icons.delete_outline_rounded,
                  onTap: () => _confirmClear(context, ref),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    // Destructive and not obviously recoverable, so it asks first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ล้างข้อมูลโปรไฟล์?'),
        content: const Text(
          'ชื่อและอีเมลจะถูกลบออกจากเครื่อง งานและโน้ตของคุณจะยังอยู่',
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

    if (confirmed ?? false) {
      ref.read(profileProvider.notifier).clear();
    }
  }
}

Future<void> _editProfile(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) async {
  final nameController = TextEditingController(text: profile.displayName);
  final emailController = TextEditingController(text: profile.email);

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      // Lifts the fields above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.screenPadding,
          4,
          DesignTokens.screenPadding,
          24,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('แก้ไขโปรไฟล์',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: DesignTokens.space5),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'ชื่อที่แสดง'),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  // Last field: the key commits the form rather than doing
                  // nothing, which is what a bare "return" would do here.
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => Navigator.of(sheetContext).pop(true),
                  decoration: const InputDecoration(
                    hintText: 'อีเมล (ไม่บังคับ)',
                  ),
                ),
                const SizedBox(height: DesignTokens.space6),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (saved ?? false) {
    ref.read(profileProvider.notifier)
      ..setName(nameController.text)
      ..setEmail(emailController.text);
  }

  nameController.dispose();
  emailController.dispose();
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          height: DesignTokens.minTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.onHero.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: Border.all(
              color: palette.onHero.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: palette.onHero),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge
                      ?.copyWith(color: palette.onHero),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: context.text.labelLarge
            ?.copyWith(color: context.colors.onSurfaceVariant),
      );
}

/// One card holding a set of rows, with hairlines between them.
class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: context.colors.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A full-width selectable row.
///
/// Full width is the point: the segmented control this replaces gave each
/// Thai label a third of the screen, which was not enough for "ชัดสูงสุด"
/// and produced the overlap. Here a long label simply wraps.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? cs.secondaryContainer : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? cs.onSecondaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: DesignTokens.space3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: context.text.bodyLarge?.copyWith(
                          color: selected
                              ? cs.onSecondaryContainer
                              : cs.onSurface,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: context.text.bodySmall?.copyWith(
                          color: selected
                              ? cs.onSecondaryContainer.withValues(alpha: 0.78)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.space3),
                // The check carries the selection for anyone who cannot rely
                // on the fill color alone.
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 22,
                  color: selected ? cs.onSecondaryContainer : cs.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.text.bodyLarge)),
          const SizedBox(width: DesignTokens.space3),
          Text(
            value,
            style: context.text.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
