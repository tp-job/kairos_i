import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Template accent — a pale lavender used for the category label.
  static const _lavender = Color(0xFFD6D6FB);
  static const _canvas = Color(0xFF0C0C0C);

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

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: _canvas,
          onRefresh: () => ref.refresh(newsProvider.future),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _Header()),
              const SliverToBoxAdapter(child: _CategoryLabel(lavender: _lavender)),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.auto_stories_rounded, size: 20, color: NewsScreen._canvas),
              ),
              Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 22),
                  const SizedBox(width: 16),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Articles',
            style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600, letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Latest article', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.lavender});
  final Color lavender;

  @override
  Widget build(BuildContext context) {
    // Extra bottom padding leaves room for the hero card to slide up under
    // it (the card is translated up by 24 to create the overlap).
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 44),
      decoration: BoxDecoration(
        color: lavender,
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
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.black),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal finance',
                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Everything you need to know',
                    style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              const Text('3-5min', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Icon(Icons.schedule, size: 14, color: Colors.black.withValues(alpha: 0.55)),
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
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder (network images from the reference are dropped
          // to keep the app self-contained and offline-friendly).
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3F3F46), Color(0xFF18181B)],
              ),
            ),
            child: const Center(child: Icon(Icons.image_outlined, color: Colors.white24, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (source != null) ...[
                  Text(
                    source!.toUpperCase(),
                    style: const TextStyle(
                      color: DesignTokens.textFaint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                if (loading)
                  const _BodySkeleton()
                else
                  Text(
                    body,
                    style: const TextStyle(color: DesignTokens.textMuted, fontSize: 15, height: 1.5),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.article_outlined, color: Colors.white54, size: 22),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  article.sourceName,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_outward_rounded, color: Colors.white.withValues(alpha: 0.4), size: 18),
        ],
      ),
    );
  }
}

class _BodySkeleton extends StatelessWidget {
  const _BodySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 12,
              width: i == 2 ? 160 : double.infinity,
              decoration: BoxDecoration(
                color: DesignTokens.hairline,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
      ],
    );
  }
}
