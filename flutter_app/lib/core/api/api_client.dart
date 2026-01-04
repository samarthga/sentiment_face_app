import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the API client singleton.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// HTTP client for communicating with the sentiment backend.
class ApiClient {
  late final Dio _dio;

  // Production URL from environment, fallback to localhost for development
  static const String _prodApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get _baseUrl {
    // If production URL is set via environment, use it
    if (_prodApiUrl.isNotEmpty) {
      return _prodApiUrl;
    }
    // In release mode on web, use relative URLs (same origin)
    if (kIsWeb && kReleaseMode) {
      return '';  // Use relative URLs for same-origin backend
    }
    // Development fallback
    return 'http://localhost:8000';
  }

  static String get _wsBaseUrl {
    if (_prodApiUrl.isNotEmpty) {
      // Convert https to wss, http to ws
      return _prodApiUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    }
    if (kIsWeb && kReleaseMode) {
      return '';  // Will be constructed from window.location in WebSocket code
    }
    return 'ws://localhost:8000';
  }

  String get baseUrl => _baseUrl;
  String get wsBaseUrl => _wsBaseUrl;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          // options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) {
          // Handle common errors
          handler.next(error);
        },
      ),
    );
  }

  /// Performs a GET request.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Performs a POST request.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final response = await _dio.post(
      path,
      data: body,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Performs a PUT request.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.put(
      path,
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Performs a DELETE request.
  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
