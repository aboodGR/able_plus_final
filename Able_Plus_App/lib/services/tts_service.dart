// ──────────────────────────────────────────────────────────────
// tts_service.dart  —  TTS Service موحّد (Mobile + Web)
//
// المنطق:
//   • Web  → يستخدم Web Speech API عبر tts_web.dart
//   • Mobile/Desktop → يستخدم flutter_tts
//
// اللغة تُحدَّث تلقائياً من LanguageNotifier في theme_providers.dart
// ──────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Conditional import: على الويب يأخذ tts_web.dart، وعلى غيره tts_stub.dart
import 'tts_stub.dart'
    if (dart.library.js) 'tts_web.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  FlutterTts? _engine;
  bool _isReady = false;
  String _lang = 'en'; // اللغة الحالية

  bool   get isReady     => _isReady;
  String get currentLang => _lang;

  // ── تهيئة المحرك وحفظ اللغة ──────────────────────────────
  Future<void> init({String lang = 'en'}) async {
    _lang = lang;

    if (kIsWeb) {
      // على الويب نعتمد على Web Speech API — لا نحتاج flutter_tts
      _isReady = true;
      return;
    }

    try {
      _engine ??= FlutterTts();

      // إعدادات الصوت الأساسية
      await _engine!.setVolume(1.0);
      await _engine!.setPitch(1.0);

      // تطبيق اللغة والسرعة مباشرة عند الـ init
      final langCode = lang == 'ar' ? 'ar-SA' : 'en-US';
      final rate     = lang == 'ar' ? 0.4 : 0.5;
      await _engine!.setLanguage(langCode);
      await _engine!.setSpeechRate(rate);

      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
  }

  // ── قراءة النص ────────────────────────────────────────────
  Future<void> speak(String text, {bool enabled = true, String? lang}) async {
    if (!enabled || text.trim().isEmpty) return;

    final useLang = lang ?? _lang;

    // ── Web ──
    if (kIsWeb) {
      speakOnWeb(text, useLang); // من tts_web.dart (أو stub على mobile)
      return;
    }

    // ── Mobile / Desktop ──
    if (!_isReady) await init(lang: useLang);

    try {
      final langCode = useLang == 'ar' ? 'ar-SA' : 'en-US';
      final rate     = useLang == 'ar' ? 0.4 : 0.5;

      await _engine!.setLanguage(langCode);
      await _engine!.setSpeechRate(rate);
      await _engine!.stop();
      await _engine!.speak(text);
    } catch (_) {}
  }

  // ── إيقاف الكلام ──────────────────────────────────────────
  Future<void> stop() async {
    if (kIsWeb) {
      stopOnWeb(); // من tts_web.dart (أو stub على mobile)
      return;
    }
    try {
      await _engine?.stop();
    } catch (_) {}
  }
}