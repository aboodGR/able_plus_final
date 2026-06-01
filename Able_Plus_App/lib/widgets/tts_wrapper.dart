import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/services/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TtsWrapper extends ConsumerStatefulWidget {
  const TtsWrapper({super.key, required this.text, required this.child});
  final String text;
  final Widget child;

  @override
  ConsumerState<TtsWrapper> createState() => _TtsWrapperState();
}

class _TtsWrapperState extends ConsumerState<TtsWrapper> {
  bool _inside = false;

  void _speak() {
    final enabled = ref.read(ttsEnabledProvider);
    if (!enabled) return;
    final lang = ref.read(languageProvider).languageCode;
    TtsService.instance.speak(widget.text, enabled: true, lang: lang);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _isDesktop) {
      return MouseRegion(
        // hitTestBehavior على MouseRegion غير موجود مباشرة
        // بس نستخدم opaque على Container عشان يمنع الـ bubble
        onEnter: (_) {
          if (!_inside) {
            _inside = true;
            _speak();
          }
        },
        onExit: (_) => _inside = false,
        // ── المهم: نحط AbsorbPointer=false وContainer بحجم محدد ──
        child: Container(
          // بنضيف color شفاف عشان يمنع الـ hit test يطلع للأب
          color: Colors.transparent,
          child: widget.child,
        ),
      );
    }

    return GestureDetector(
      onLongPress: _speak,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }

  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}