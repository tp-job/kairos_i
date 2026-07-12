import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../orchestrator/providers/orchestrator_provider.dart';
import '../data/news_service.dart';
import '../models/news_model.dart';

final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService(ref.watch(dioProvider));
});

/// Two-stage pipeline: fetch raw headlines, then ask the AI orchestrator
/// to compress each into a 3-line summary (Feature 5.2). Both stages
/// are awaited inside one FutureProvider — from the UI's point of view
/// it's still just one loading -> data transition.
final newsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final service = ref.watch(newsServiceProvider);
  final ai = ref.watch(aiServiceProvider);

  final articles = await service.getTechHeadlines();

  final summarized = await Future.wait(
    articles.map((article) async {
      try {
        final summary = await ai.summarizeToThreeLines(
          title: article.title,
          description: article.description,
        );
        return article.copyWithSummary(summary);
      } catch (_) {
        // If the AI call fails, fall back to the raw description
        // instead of failing the whole card.
        return article;
      }
    }),
  );

  return summarized;
});
