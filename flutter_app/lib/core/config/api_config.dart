import 'local_secrets.dart';

/// API configuration for external services.
class ApiConfig {
  /// Google Gemini API key for image generation.
  /// In production: Set via --dart-define=GEMINI_API_KEY=xxx
  /// For local dev: Set in local_secrets.dart (gitignored)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: _localGeminiApiKey,
  );

  /// Backend API base URL.
  static const String backendBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // Fallback for local development from local_secrets.dart
  static const String _localGeminiApiKey = LocalSecrets.geminiApiKey;
}
