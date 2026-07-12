class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.sourceName,
    this.aiSummary,
  });

  final String title;
  final String description;
  final String url;
  final String sourceName;

  /// Filled in later by the Orchestrator's summarization pass
  /// (Feature 5.2: 3-line bullet summaries). Null until then, so the
  /// card can show the raw description as a fallback immediately.
  final String? aiSummary;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      sourceName: (json['source'] as Map<String, dynamic>?)?['name']
              as String? ??
          'Unknown',
    );
  }

  NewsArticle copyWithSummary(String summary) {
    return NewsArticle(
      title: title,
      description: description,
      url: url,
      sourceName: sourceName,
      aiSummary: summary,
    );
  }
}
