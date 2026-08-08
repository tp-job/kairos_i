import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'models/news_model.dart';
import 'providers/news_provider.dart';

/// Article reading page — the "Articles" view from the `news` reference:
/// a near-black canvas, a large title, an overlapping lavender category
/// label, and a white hero article card. Bound to [newsProvider] so the
/// hero and the list below reflect live headlines; the reference's static
/// copy is used as the fallback while loading or on error.
class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  static const _fallbackTitle = 'How to keep your account secure?';
  static const _fallbackBody =
      'Your browser history holds personal information that can be easily '
      'tracked. Cyber criminals can use what they learn from your browsing '
      'habits to customize their attacks — for example, sending a link to a '
      'fake website that looks like one you frequently visit to trick you '
      'into providing your username and password.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    final cs = context.colors;

    return Scaffold(
      // Transparent so the ambient mesh backdrop bleeds through.
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surfaceContainerHigh,
          onRefresh: () => ref.refresh(newsProvider.future),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _Header()),
              const SliverToBoxAdapter(child: _CategoryLabel()),
              SliverToBoxAdapter(
                child: news.when(
                  loading: () => const _HeroArticleCard(
                    title: _fallbackTitle,
                    body: _fallbackBody,
                    loading: true,
                  ),
                  error: (_, _) => const _HeroArticleCard(
                    title: _fallbackTitle,
                    body: _fallbackBody,
                  ),
                  data: (items) {
                    final hero = items.isNotEmpty ? items.first : null;
                    return _HeroArticleCard(
                      title: hero?.title ?? _fallbackTitle,
                      body: hero?.aiSummary ?? hero?.description ?? _fallbackBody,
                      source: hero?.sourceName,
                    );
                  },
                ),
              ),
              news.maybeWhen(
                data: (items) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      18, 8, 18, DesignTokens.navBarClearance),
                  sliver: SliverList.separated(
                    itemCount: items.length > 1 ? items.length - 1 : 0,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _ArticleRow(article: items[i + 1]),
                  ),
                ),
                orElse: () => const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_stories_rounded, size: 20, color: cs.onPrimary),
              ),
              Row(
                children: [
                  Icon(Icons.search, color: cs.onSurface, size: 22),
                  const SizedBox(width: 16),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications_none_rounded, color: cs.onSurface, size: 22),
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Articles', style: context.text.displayLarge),
          const SizedBox(height: DesignTokens.space2),
          Row(
            children: [
              Text(
                'Latest article',
                style: context.text.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel();

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final bgColor = cs.primaryContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 44),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.onPrimaryContainer.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_rounded, size: 16, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal finance',
                    style: context.text.titleSmall
                        ?.copyWith(color: cs.onPrimaryContainer)),
                const SizedBox(height: 2),
                Text('Everything you need to know',
                    style: context.text.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.75))),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                '3-5min',
                style: context.text.labelMedium?.copyWith(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.75)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.schedule,
                  size: 14,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.75)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroArticleCard extends StatelessWidget {
  const _HeroArticleCard({
    required this.title,
    required this.body,
    this.source,
    this.loading = false,
  });

  final String title;
  final String body;
  final String? source;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final palette = context.palette;
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                gradient: palette.heroGradient,
              ),
              child: Center(
                child: Icon(Icons.image_outlined,
                    color: palette.onHeroVariant, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (source != null) ...[
                    Text(
                      source!.toUpperCase(),
                      style: context.text.labelSmall
                          ?.copyWith(color: cs.primary, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(title, style: context.text.headlineSmall),
                  const SizedBox(height: DesignTokens.space3),
                  if (loading)
                    const _BodySkeleton()
                  else
                    Text(
                      body,
                      style: context.text.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article});
  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.article_outlined,
                color: cs.onPrimaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  article.sourceName,
                  style: context.text.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_outward_rounded,
              color: cs.onSurfaceVariant, size: 18),
        ],
      ),
    );
  }
}

class _BodySkeleton extends StatelessWidget {
  const _BodySkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 12,
              width: i == 2 ? 160 : double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
      ],
    );
  }
}
