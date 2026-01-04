import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Service for generating hyper-realistic face images using Google Gemini API.
class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  final String apiKey;
  final Dio _dio;

  GeminiService({required this.apiKey}) : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 120),
  ));

  /// Generate a face image using Gemini's image generation capability.
  Future<Uint8List?> generateFaceImage({
    required String prompt,
    int width = 512,
    int height = 512,
  }) async {
    // Try different models in order of preference
    final models = [
      'gemini-2.0-flash-exp-image-generation',
      'gemini-2.0-flash-exp',
      'gemini-1.5-flash',
    ];

    for (final model in models) {
      final result = await _tryGenerateWithModel(model, prompt);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  Future<Uint8List?> _tryGenerateWithModel(String model, String prompt) async {
    try {
      debugPrint('Trying model: $model');

      final response = await _dio.post(
        '/models/$model:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['IMAGE', 'TEXT'],
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE'
            },
          ],
        },
      );

      if (response.statusCode == 200) {
        return _extractImageFromResponse(response.data);
      }

      return null;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      debugPrint('Model $model error: $errorData');

      // Check if it's a rate limit error
      if (e.response?.statusCode == 429) {
        final retryInfo = errorData?['error']?['details'];
        if (retryInfo != null) {
          for (final detail in retryInfo) {
            if (detail['@type']?.contains('RetryInfo') == true) {
              final delay = detail['retryDelay'] as String?;
              if (delay != null) {
                final seconds = int.tryParse(delay.replaceAll('s', '')) ?? 30;
                debugPrint('Rate limited. Waiting ${seconds}s...');
                await Future.delayed(Duration(seconds: seconds + 1));
                // Retry once after waiting
                return _tryGenerateWithModel(model, prompt);
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error with model $model: $e');
      return null;
    }
  }

  Uint8List? _extractImageFromResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('No candidates in response');
        return null;
      }

      final content = candidates[0]['content'];
      if (content == null) {
        debugPrint('No content in candidate');
        return null;
      }

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        debugPrint('No parts in content');
        return null;
      }

      for (final part in parts) {
        // Check for inline image data
        if (part['inlineData'] != null) {
          final mimeType = part['inlineData']['mimeType'] as String?;
          final imageData = part['inlineData']['data'] as String?;

          if (imageData != null) {
            debugPrint('Found image with mimeType: $mimeType');
            return base64Decode(imageData);
          }
        }

        // Check for file data (alternative format)
        if (part['fileData'] != null) {
          debugPrint('Found file data (not yet supported)');
        }

        // Log text parts
        if (part['text'] != null) {
          debugPrint('Text response: ${(part['text'] as String).substring(0, 100)}...');
        }
      }

      debugPrint('No image data found in parts');
      return null;
    } catch (e) {
      debugPrint('Error extracting image: $e');
      return null;
    }
  }

  /// Generate face using Gemini 2.0 with image generation.
  Future<Uint8List?> generateFaceWithGemini2({
    required String prompt,
  }) async {
    return generateFaceImage(prompt: prompt);
  }
}
