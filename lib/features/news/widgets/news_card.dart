import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bento_card.dart';
import '../models/news_model.dart';
import '../providers/news_provider.dart';

class NewsCard extends ConsumerWidget {
  const NewsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);

    return BentoCard(
      title: 'เทรนด์เทคโนโลยี',
      icon: Icons.bolt_outlined,
      onTap: () => ref.invalidate(newsProvider),
      child: AsyncCardBody<List<NewsArticle>>(
        value: news,
        builder: (context, data) => ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, _) => const Divider(height: 16),
          itemBuilder: (context, i) => _NewsRow(article: data[i]),
        ),
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          article.aiSummary ?? article.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        Text(
          article.sourceName,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
