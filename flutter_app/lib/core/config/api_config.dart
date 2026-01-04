/// API configuration for external services.
class ApiConfig {
  /// Google Gemini API key for image generation.
  /// In production, use environment variables or secure storage.
  static const String geminiApiKey = 'AIzaSyA6V8Gsr0OrIe1dNa5DRhtUjZrBCU2d94A';

  /// Backend API base URL.
  static const String backendBaseUrl = 'http://localhost:8000';
}
