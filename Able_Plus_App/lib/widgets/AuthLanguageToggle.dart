import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/theme/app_theme.dart';

/// A compact EN / ع language pill for the auth screens (login, signups,
/// forgot-password, OTP, reset). Self-contained ConsumerWidget so the host
/// screen does NOT need to be a ConsumerWidget — just drop it into a Stack
/// (via Positioned) or an AppBar `actions:` list.
///
/// Reads/writes the existing languageProvider (StateNotifier<Locale>):
///   - current:  ref.watch(languageProvider).languageCode  -> 'en' | 'ar'
///   - change:   ref.read(languageProvider.notifier).setLanguage('ar')
/// The choice persists via SharedPreferences inside LanguageNotifier.
class AuthLanguageToggle extends ConsumerWidget {
  const AuthLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = ref.watch(languageProvider).languageCode;
    final isArabic = langCode == 'ar';

    final accentColor = isDark
        ? AbleColors.darkSecondary
        : AbleColors.lightPrimaryDark;

    final mutedColor = isDark
        ? AbleColors.darkTextMuted
        : AbleColors.lightTextMuted;

    final pillColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.72);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.60);

    void select(String code) {
      if (code == langCode) return;
      ref.read(languageProvider.notifier).setLanguage(code);
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'EN',
            selected: !isArabic,
            accentColor: accentColor,
            mutedColor: mutedColor,
            onTap: () => select('en'),
          ),
          _Segment(
            label: 'ع',
            selected: isArabic,
            accentColor: accentColor,
            mutedColor: mutedColor,
            onTap: () => select('ar'),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.mutedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : mutedColor,
            ),
          ),
        ),
      ),
    );
  }
}