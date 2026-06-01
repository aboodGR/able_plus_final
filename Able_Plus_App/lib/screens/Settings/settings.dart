import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/services/tts_service.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsEngineProvider = FutureProvider<FlutterTts>((ref) async {
  final lang = ref.watch(languageProvider).languageCode;
  final tts = FlutterTts();
  await tts.setLanguage(lang == 'ar' ? 'ar-SA' : 'en-US');
  await tts.setSpeechRate(0.5);
  await tts.setVolume(1.0);
  await tts.setPitch(1.0);
  return tts;
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  String _onOff(bool value, String lang) =>
      value ? (lang == 'ar' ? 'تشغيل' : 'On') : (lang == 'ar' ? 'إيقاف' : 'Off');

  void _speak(String text) {
    final enabled = ref.read(ttsEnabledProvider);
    final lang = ref.read(languageProvider).languageCode;
    TtsService.instance.speak(text, enabled: enabled, lang: lang);
  }

  @override
  void initState() {
    super.initState();
    // ── اقرأ كل محتوى الصفحة لما تفتح ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(ttsEnabledProvider)) return;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      final lang = ref.read(languageProvider).languageCode;
      final isDark = ref.read(themeProvider);
      final tts = ref.read(ttsEnabledProvider);
      final colorBlind = ref.read(colorblindModeProvider);
      final locale = ref.read(languageProvider);
      final langName = locale.languageCode == 'ar' ? 'العربية' : 'English';
      final sep = lang == 'ar' ? '، ' : ', ';

      final fullText = [
        l10n.settings,
        l10n.appearance,
        '${l10n.darkMode}: ${_onOff(isDark, lang)}',
        '${l10n.language}: $langName',
        l10n.accessibility,
        '${l10n.textToSpeech}: ${_onOff(tts, lang)}',
        '${l10n.colorBlindMode}: ${_onOff(colorBlind, lang)}',
      ].join(sep);

      TtsService.instance.speak(fullText, enabled: true, lang: lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(languageProvider).languageCode;
    final isDark = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);
    final tts = ref.watch(ttsEnabledProvider);
    final colorBlind = ref.watch(colorblindModeProvider);
    final ttsEngine = ref.watch(ttsEngineProvider);
    final isTtsLoading = ttsEngine.isLoading;

    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);

    return AbleScaffold(
      title: l10n.settings,
      currentIndex: 4,
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── Appearance ──
          _SectionHeader(title: l10n.appearance, color: accentColor),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            // Dark Mode
            TtsWrapper(
              text: '${l10n.darkMode}: ${_onOff(isDark, lang)}',
              child: _SettingsTile(
                icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                title: l10n.darkMode,
                accentColor: accentColor,
                trailing: Switch.adaptive(
                  value: isDark,
                  activeColor: accentColor,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).setDarkMode(value);
                    _speak('${l10n.darkMode}: ${_onOff(value, lang)}');
                  },
                ),
              ),
            ),
            _Divider(),
            // Language
            TtsWrapper(
              text: '${l10n.language}: ${locale.languageCode == 'ar' ? 'العربية' : 'English'}',
              child: _SettingsTile(
                icon: Icons.language_rounded,
                title: l10n.language,
                accentColor: accentColor,
                trailing: _LanguageDropdown(
                  currentCode: locale.languageCode,
                  accentColor: accentColor,
                  textColor: textColor,
                  onChanged: (code) {
                    if (code != null) {
                      ref.read(languageProvider.notifier).setLanguage(code);
                      final langName = code == 'ar' ? 'العربية' : 'English';
                      _speak('${l10n.language}: $langName');
                    }
                  },
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Accessibility ──
          _SectionHeader(title: l10n.accessibility, color: accentColor),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            // TTS
            TtsWrapper(
              text: '${l10n.textToSpeech}: ${_onOff(tts, lang)}',
              child: _SettingsTile(
                icon: Icons.record_voice_over_rounded,
                title: l10n.textToSpeech,
                accentColor: accentColor,
                trailing: isTtsLoading
                    ? SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: accentColor),
                      )
                    : Switch.adaptive(
                        value: tts,
                        activeColor: accentColor,
                        onChanged: ttsEngine.hasValue
                            ? (value) {
                                ref.read(ttsEnabledProvider.notifier).setTts(value);
                                if (value) {
                                  TtsService.instance.speak(
                                    lang == 'ar' ? 'تم تفعيل قراءة النص' : 'Text to speech enabled',
                                    enabled: true, lang: lang,
                                  );
                                }
                              }
                            : null,
                      ),
              ),
            ),
            _Divider(),
            // Color Blind
            TtsWrapper(
              text: '${l10n.colorBlindMode}: ${_onOff(colorBlind, lang)}. ${l10n.deuteranopiaFilter}',
              child: _ColorBlindTile(
                colorBlind: colorBlind,
                accentColor: accentColor,
                textColor: textColor,
                mutedColor: mutedColor,
                l10n: l10n,
                onChanged: (value) {
                  ref.read(colorblindModeProvider.notifier).setColorBlind(value);
                  _speak('${l10n.colorBlindMode}: ${_onOff(value, lang)}');
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ColorBlindTile extends StatelessWidget {
  const _ColorBlindTile({required this.colorBlind, required this.accentColor, required this.textColor, required this.mutedColor, required this.l10n, required this.onChanged});
  final bool colorBlind;
  final Color accentColor, textColor, mutedColor;
  final AppLocalizations l10n;
  final ValueChanged<bool> onChanged;

  static const _normalColors = [Color(0xFFE53935), Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFFFDD835)];
  static const _cbColors = [Color(0xFF4B9CD3), Color(0xFF9B8FB8), Color(0xFF4B9CD3), Color(0xFFF0E442)];

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.palette_outlined, color: accentColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.colorBlindMode, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
            Text(l10n.deuteranopiaFilter, style: TextStyle(color: mutedColor, fontSize: 11)),
          ])),
          Switch.adaptive(value: colorBlind, activeColor: accentColor, onChanged: onChanged),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: colorBlind ? Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.howColorsAppear, style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Column(children: [
                  Text(l10n.normal, style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(children: _normalColors.map((c) => Expanded(child: Container(height: 22, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))))).toList()),
                ])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Transform.flip(flipX: isRtl, child: Icon(Icons.arrow_forward_rounded, size: 16, color: mutedColor))),
                Expanded(child: Column(children: [
                  Text(l10n.withFilter, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(children: _cbColors.map((c) => Expanded(child: Container(height: 22, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))))).toList()),
                ])),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l10n.colorBlindModeDesc, style: TextStyle(color: mutedColor, fontSize: 12, height: 1.4))),
                ]),
              ),
            ]),
          ) : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title; final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 2),
    child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.2)),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AbleTheme.glassCard(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AbleTheme.glassBorder(context))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.accentColor, required this.trailing});
  final IconData icon; final String title; final Color accentColor; final Widget trailing;
  @override
  Widget build(BuildContext context) {
    final textColor = AbleTheme.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: accentColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500))),
        trailing,
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 64, endIndent: 16, color: AbleTheme.glassBorder(context));
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.currentCode, required this.accentColor, required this.textColor, required this.onChanged});
  final String currentCode; final Color accentColor, textColor; final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: accentColor.withOpacity(0.3))),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentCode, isDense: true,
        icon: Icon(Icons.expand_more_rounded, color: accentColor, size: 20),
        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
        dropdownColor: AbleTheme.isDark(context) ? const Color(0xFF182437) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        items: [
          DropdownMenuItem(value: 'en', child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.language_rounded, size: 16, color: accentColor), const SizedBox(width: 6), Text('English', style: TextStyle(color: textColor))])),
          DropdownMenuItem(value: 'ar', child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.language_rounded, size: 16, color: accentColor), const SizedBox(width: 6), Text('العربية', style: TextStyle(color: textColor))])),
        ],
        onChanged: onChanged,
      ),
    ),
  );
}