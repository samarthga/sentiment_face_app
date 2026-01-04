/// API configuration for external services.
class ApiConfig {
  /// Google Gemini API key for image generation.
  /// Loaded from environment variable at build time.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Backend API base URL.
  /// In production (web release), use relative URLs for same-origin.
  static const String backendBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
