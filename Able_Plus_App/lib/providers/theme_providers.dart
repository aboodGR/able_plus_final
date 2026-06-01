import 'dart:async';

import 'package:ableplusproject/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// THEME (Dark Mode)
// ─────────────────────────────────────────────
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false) {
    _hydrate();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _hydrate();
    });
  }

  static const _prefsKey = 'pref_dark_mode';
  StreamSubscription<AuthState>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localValue = prefs.getBool(_prefsKey);
      if (localValue != null && localValue != state) state = localValue;
    } catch (_) {}

    try {
      final supabase = Supabase.instance.client;
      final authUserId = supabase.auth.currentUser?.id;
      if (authUserId == null) return;

      final row = await supabase
          .from('user_preferences')
          .select('dark_mode')
          .eq('user_id', authUserId)
          .maybeSingle();

      if (row != null && row['dark_mode'] is bool) {
        final remoteValue = row['dark_mode'] as bool;
        if (remoteValue != state) state = remoteValue;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_prefsKey, remoteValue);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
    try {
      final supabase = Supabase.instance.client;
      final authUserId = supabase.auth.currentUser?.id;
      if (authUserId == null) return;
      await supabase.from('user_preferences').upsert({
        'user_id': authUserId,
        'dark_mode': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
  (ref) => ThemeNotifier(),
);

// ─────────────────────────────────────────────
// LANGUAGE — بيحدث TtsService فوراً لما تتغير اللغة
// ─────────────────────────────────────────────
class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) {
    _hydrate();
  }

  static const _prefsKey = 'pref_language';

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved != state.languageCode) {
        state = Locale(saved);
        // ← بيحدث TtsService باللغة المحفوظة
        await TtsService.instance.init(lang: saved);
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String langCode) async {
    state = Locale(langCode);
    // ← بيحدث TtsService فوراً لما يغير اللغة
    await TtsService.instance.init(lang: langCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, langCode);
    } catch (_) {}
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>(
  (ref) => LanguageNotifier(),
);

// ─────────────────────────────────────────────
// TTS
// ─────────────────────────────────────────────
class TtsNotifier extends StateNotifier<bool> {
  // الحالة الافتراضية: TTS شغّال. لو ما في قيمة محفوظة بـ SharedPreferences
  // (المرة الأولى لفتح التطبيق) رح يضل true. لو المستخدم طفّاه لاحقاً
  // _hydrate رح يقرأ القيمة المحفوظة ويحترم اختياره.
  TtsNotifier() : super(true) {
    _hydrate();
    TtsService.instance.init();
  }

  static const _prefsKey = 'pref_tts';

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefsKey);
      if (saved != null) state = saved;
    } catch (_) {}
  }

  Future<void> setTts(bool value) async {
    state = value;
    if (value && !TtsService.instance.isReady) {
      await TtsService.instance.init();
    }
    if (!value) {
      await TtsService.instance.stop();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }
}

final ttsEnabledProvider = StateNotifierProvider<TtsNotifier, bool>(
  (ref) => TtsNotifier(),
);

// ─────────────────────────────────────────────
// COLOR BLIND MODE
// ─────────────────────────────────────────────
class ColorBlindNotifier extends StateNotifier<bool> {
  ColorBlindNotifier() : super(false) {
    _hydrate();
  }

  static const _prefsKey = 'pref_colorblind';

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefsKey);
      if (saved != null) state = saved;
    } catch (_) {}
  }

  Future<void> setColorBlind(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }
}

final colorblindModeProvider = StateNotifierProvider<ColorBlindNotifier, bool>(
  (ref) => ColorBlindNotifier(),
);

const List<double> deuteranopiaMatrix = [
  0.625, 0.375, 0,     0, 0,
  0.700, 0.300, 0,     0, 0,
  0,     0.300, 0.700, 0, 0,
  0,     0,     0,     1, 0,
];