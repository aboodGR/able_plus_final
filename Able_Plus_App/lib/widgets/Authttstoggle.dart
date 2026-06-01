import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/theme/App_theme.dart';

/// A compact text-to-speech ON / OFF pill for the auth screens (login,
/// signups, forgot-password, OTP, reset). Self-contained ConsumerWidget so the
/// host screen does NOT need to be a ConsumerWidget — just drop it into a Stack
/// (via Positioned) or an AppBar `actions:` list, exactly like AuthLanguageToggle.
///
/// Reads/writes the existing ttsEnabledProvider (StateNotifier<bool>):
///   - current:  ref.watch(ttsEnabledProvider)              -> true | false
///   - change:   ref.read(ttsEnabledProvider.notifier).setTts(value)
/// The choice persists via SharedPreferences inside TtsNotifier.
class AuthTtsToggle extends ConsumerWidget {
  const AuthTtsToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = ref.watch(ttsEnabledProvider);

    final accentColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    final pillColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.72);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.60);

    final spokenLabel = enabled
        ? (l10n.localeName == 'ar'
            ? 'إيقاف القراءة الصوتية'
            : 'Turn voice reading off')
        : (l10n.localeName == 'ar'
            ? 'تشغيل القراءة الصوتية'
            : 'Turn voice reading on');

    return Tooltip(
      message: spokenLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(ttsEnabledProvider.notifier).setTts(!enabled);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: enabled ? accentColor : pillColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: enabled ? accentColor : borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  enabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  size: 18,
                  color: enabled ? Colors.white : mutedColor,
                ),
                const SizedBox(width: 6),
                Text(
                  enabled
                      ? (l10n.localeName == 'ar' ? 'صوت' : 'TTS')
                      : (l10n.localeName == 'ar' ? 'صوت' : 'TTS'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}