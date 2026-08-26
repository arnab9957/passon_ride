import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import '../i18n/strings.g.dart';
import '../services/libretranslate_service.dart';

/// Pre-configured Native Language Info Item
class NativeLanguageItem {
  final String code;
  final String englishName;
  final String nativeName;
  final String flagEmoji;

  const NativeLanguageItem({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flagEmoji,
  });
}

class LanguageProvider extends ChangeNotifier {
  final LibreTranslateService _service = LibreTranslateService();
  final GoogleTranslator _googleTranslator = GoogleTranslator();

  static const List<NativeLanguageItem> supportedLanguages = [
    NativeLanguageItem(code: 'en', englishName: 'English', nativeName: 'English', flagEmoji: '🇬🇧'),
    NativeLanguageItem(code: 'hi', englishName: 'Hindi', nativeName: 'हिंदी', flagEmoji: '🇮🇳'),
    NativeLanguageItem(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা', flagEmoji: '🇮🇳'),
    NativeLanguageItem(code: 'es', englishName: 'Spanish', nativeName: 'Español', flagEmoji: '🇪🇸'),
    NativeLanguageItem(code: 'fr', englishName: 'French', nativeName: 'Français', flagEmoji: '🇫🇷'),
    NativeLanguageItem(code: 'de', englishName: 'German', nativeName: 'Deutsch', flagEmoji: '🇩🇪'),
    NativeLanguageItem(code: 'ja', englishName: 'Japanese', nativeName: '日本語', flagEmoji: '🇯🇵'),
    NativeLanguageItem(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी', flagEmoji: '🇮🇳'),
    NativeLanguageItem(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்', flagEmoji: '🇮🇳'),
    NativeLanguageItem(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు', flagEmoji: '🇮🇳'),
    NativeLanguageItem(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી', flagEmoji: '🇮🇳'),
    NativeLanguageItem(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ', flagEmoji: '🇮🇳'),
  ];

  String _currentLanguageCode = 'en';
  String _serverUrl = 'http://localhost:5000';
  String _apiKey = '';
  bool? _isServerConnected;
  int _serverLatencyMs = -1;

  // In-memory translation LRU cache mapping '${langCode}_${text}' -> translatedText
  final Map<String, String> _cache = {};

  LanguageProvider() {
    _loadPreferences();
  }

  String get currentLanguageCode => _currentLanguageCode;
  String get serverUrl => _serverUrl;
  String get apiKey => _apiKey;
  bool? get isServerConnected => _isServerConnected;
  int get serverLatencyMs => _serverLatencyMs;

  NativeLanguageItem get activeLanguage {
    return supportedLanguages.firstWhere(
      (l) => l.code == _currentLanguageCode,
      orElse: () => supportedLanguages.first,
    );
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguageCode = prefs.getString('user_target_language') ?? 'en';

      // Update Slang locale
      _applySlangLocale(_currentLanguageCode);

      final savedServerUrl = prefs.getString('libretranslate_server_url');
      if (savedServerUrl != null && savedServerUrl.isNotEmpty) {
        _serverUrl = savedServerUrl;
        _service.setBaseUrl(_serverUrl);
      }
      _apiKey = prefs.getString('libretranslate_api_key') ?? '';
      if (_apiKey.isNotEmpty) {
        _service.setApiKey(_apiKey);
      }
      notifyListeners();
      checkServerConnection();
    } catch (_) {}
  }

  void _applySlangLocale(String langCode) {
    try {
      final matchedLocale = AppLocale.values.firstWhere(
        (l) => l.languageCode == langCode,
        orElse: () => AppLocale.en,
      );
      LocaleSettings.setLocale(matchedLocale);
    } catch (e) {
      debugPrint('Slang locale switch warning: $e');
    }
  }

  Future<bool> checkServerConnection([String? customUrl]) async {
    final latency = await _service.checkHealth(customUrl ?? _serverUrl);
    _isServerConnected = latency >= 0;
    _serverLatencyMs = latency;
    notifyListeners();
    return _isServerConnected ?? false;
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguageCode == langCode) return;
    _currentLanguageCode = langCode;

    // Apply Slang static localization
    _applySlangLocale(langCode);

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_target_language', langCode);
    } catch (_) {}
  }

  Future<void> setServerUrl(String url) async {
    if (url.trim().isEmpty) return;
    _serverUrl = url.trim();
    _service.setBaseUrl(_serverUrl);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('libretranslate_server_url', _serverUrl);
      await checkServerConnection();
    } catch (_) {}
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    _service.setApiKey(_apiKey);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('libretranslate_api_key', _apiKey);
      await checkServerConnection();
    } catch (_) {}
  }

  /// Dynamic translation using Google Translator (with fallback & LRU cache)
  Future<String> translateText(String text, {String sourceLang = 'auto'}) async {
    if (text.trim().isEmpty) return text;
    if (_currentLanguageCode == 'en' && (sourceLang == 'en' || sourceLang == 'auto')) {
      return text;
    }

    final cacheKey = '${_currentLanguageCode}_${sourceLang}_$text';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // 1. Primary: Free Google Translator scraper package
      final translation = await _googleTranslator.translate(
        text,
        from: sourceLang == 'auto' ? 'auto' : sourceLang,
        to: _currentLanguageCode,
      );
      final translated = translation.text;
      _cache[cacheKey] = translated;
      return translated;
    } catch (e) {
      debugPrint('GoogleTranslator warning, falling back to LibreTranslate: $e');
    }

    // 2. Fallback: LibreTranslate Service
    try {
      final translated = await _service.translate(
        text: text,
        targetLanguage: _currentLanguageCode,
        sourceLanguage: sourceLanguageForText(sourceLang),
      );
      _cache[cacheKey] = translated;
      return translated;
    } catch (_) {}

    return text;
  }

  /// Preload batch of strings into cache
  Future<void> preloadTranslations(List<String> texts, {String sourceLang = 'auto'}) async {
    if (_currentLanguageCode == 'en' || texts.isEmpty) return;
    for (final t in texts) {
      await translateText(t, sourceLang: sourceLang);
    }
    notifyListeners();
  }

  String sourceLanguageForText(String sourceLang) {
    if (sourceLang == 'auto') return 'auto';
    return sourceLang;
  }

  /// Synchronous cache lookup for instantaneous widget rendering
  String getCachedTranslation(String text, [String sourceLang = 'auto']) {
    if (_currentLanguageCode == 'en') return text;
    final cacheKey = '${_currentLanguageCode}_${sourceLang}_$text';
    return _cache[cacheKey] ?? text;
  }
}

