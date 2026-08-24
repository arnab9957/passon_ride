import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Language model representing installed LibreTranslate / Argos Translate packages
class LibreTranslateLanguage {
  final String code;
  final String name;

  const LibreTranslateLanguage({
    required this.code,
    required this.name,
  });

  factory LibreTranslateLanguage.fromJson(Map<String, dynamic> json) {
    return LibreTranslateLanguage(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

/// Core LibreTranslate API Service (Argos Translate Engine)
class LibreTranslateService {
  static final LibreTranslateService _instance = LibreTranslateService._internal();
  factory LibreTranslateService() => _instance;
  LibreTranslateService._internal();

  /// Default API Server Endpoints:
  /// - Web/Desktop local: http://localhost:5000
  /// - Android Emulator: http://10.0.2.2:5000
  /// - Public Fallback: https://translate.argosopentech.com (or LibreTranslate public mirror)
  String _baseUrl = kIsWeb
      ? 'http://localhost:5000'
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:5000'
          : 'http://localhost:5000');

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    if (url.trim().isNotEmpty) {
      _baseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
    }
  }

  /// Translate a string from source language to target language using LibreTranslate / /translate endpoint
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    String? customApiKey,
  }) async {
    if (text.trim().isEmpty) return text;
    if (targetLanguage == 'en' && (sourceLanguage == 'en' || sourceLanguage == 'auto')) {
      // Basic shortcut if target is English and source is English
    }

    try {
      final uri = Uri.parse('$_baseUrl/translate');
      final body = <String, dynamic>{
        'q': text,
        'source': sourceLanguage,
        'target': targetLanguage,
        'format': 'text',
      };

      if (customApiKey != null && customApiKey.isNotEmpty) {
        body['api_key'] = customApiKey;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['translatedText'] != null) {
          return data['translatedText'].toString();
        }
      }
    } catch (_) {
      // Fallback silently if local server or network mirror is unavailable

      if (kIsWeb) {
        return text;
      }

      // Public Argos Translate / LibreTranslate Mirrors (Desktop / Native only)
      final mirrors = [
        'https://translate.argosopentech.com/translate',
        'https://libretranslate.de/translate',
      ];

      for (var mirror in mirrors) {
        try {
          final fallbackUri = Uri.parse(mirror);
          final response = await http.post(
            fallbackUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'q': text,
              'source': sourceLanguage,
              'target': targetLanguage,
              'format': 'text',
            }),
          ).timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data != null && data['translatedText'] != null) {
              return data['translatedText'].toString();
            }
          }
        } catch (_) {}
      }
    }

    // Return original text gracefully if translation server is unreached
    return text;
  }

  /// Get list of supported/installed languages from LibreTranslate API (/languages)
  Future<List<LibreTranslateLanguage>> getSupportedLanguages() async {
    try {
      final uri = Uri.parse('$_baseUrl/languages');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LibreTranslateLanguage.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('LibreTranslate getSupportedLanguages error: $e');
      }
    }

    // Return popular default language list if server API is offline
    return const [
      LibreTranslateLanguage(code: 'en', name: 'English'),
      LibreTranslateLanguage(code: 'hi', name: 'Hindi'),
      LibreTranslateLanguage(code: 'bn', name: 'Bengali'),
      LibreTranslateLanguage(code: 'es', name: 'Spanish'),
      LibreTranslateLanguage(code: 'fr', name: 'French'),
      LibreTranslateLanguage(code: 'de', name: 'German'),
      LibreTranslateLanguage(code: 'ja', name: 'Japanese'),
      LibreTranslateLanguage(code: 'mr', name: 'Marathi'),
      LibreTranslateLanguage(code: 'ta', name: 'Tamil'),
      LibreTranslateLanguage(code: 'te', name: 'Telugu'),
      LibreTranslateLanguage(code: 'gu', name: 'Gujarati'),
      LibreTranslateLanguage(code: 'kn', name: 'Kannada'),
    ];
  }

  /// Detect language of input text using LibreTranslate (/detect)
  Future<String?> detectLanguage(String text) async {
    if (text.trim().isEmpty) return null;
    try {
      final uri = Uri.parse('$_baseUrl/detect');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'q': text}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['language'] != null) {
          return data[0]['language'].toString();
        }
      }
    } catch (_) {}
    return null;
  }
}
