// ──────────────────────────────────────────────────────────────
// tts_stub.dart  —  Stub للـ Mobile / Desktop
// لا يحتوي على أي import خاص بالويب
// ──────────────────────────────────────────────────────────────

/// على الـ mobile لا نحتاج Web Speech API
/// TtsService يستخدم flutter_tts مباشرة
void speakOnWeb(String text, String lang) {/* no-op on mobile */}
void stopOnWeb() {/* no-op on mobile */}