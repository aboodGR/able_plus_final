// ──────────────────────────────────────────────────────────────
// tts_web.dart  —  Web implementation using SpeechSynthesis API
// يشتغل فقط على المتصفح (dart:js_interop / dart:html)
// ──────────────────────────────────────────────────────────────
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// تنفذ الكلام على الويب عبر Web Speech API
void speakOnWeb(String text, String lang) {
  try {
    js.context.callMethod('eval', ['window.speechSynthesis.cancel()']);
    final langCode = lang == 'ar' ? 'ar-SA' : 'en-US';
    final rate    = lang == 'ar' ? 0.8 : 0.9;
    final escaped = _jsEscape(text);
    final script  = '''
      (function() {
        var msg = new SpeechSynthesisUtterance($escaped);
        msg.lang   = '$langCode';
        msg.rate   = $rate;
        msg.volume = 1;
        msg.pitch  = 1;
        window.speechSynthesis.speak(msg);
      })();
    ''';
    js.context.callMethod('eval', [script]);
  } catch (_) {}
}

void stopOnWeb() {
  try {
    js.context.callMethod('eval', ['window.speechSynthesis.cancel()']);
  } catch (_) {}
}

String _jsEscape(String text) {
  final escaped = text
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n');
  return "'$escaped'";
}