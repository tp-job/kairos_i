import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One shared Dio instance for the whole app — like a single axios
/// instance with baseOptions, reused via DI instead of `new Dio()`
/// scattered in every service.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // Uncomment while debugging a specific feature's requests/responses.
  // dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
});
