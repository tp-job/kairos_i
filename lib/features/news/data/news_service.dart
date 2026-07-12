import 'package:dio/dio.dart';
import '../../../core/env/env.dart';
import '../models/news_model.dart';

/// GNews' free "top-headlines" endpoint filtered to the technology
/// category (Feature 5.1 Keyword Filtering).
class NewsService {
  NewsService(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://gnews.io/api/v4/top-headlines';

  Future<List<NewsArticle>> getTechHeadlines({int max = 5}) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'category': 'technology',
        'lang': 'en',
        'max': max,
        'apikey': Env.gNewsApiKey,
      },
    );

    return (response.data['articles'] as List<dynamic>)
        .map((json) => NewsArticle.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
