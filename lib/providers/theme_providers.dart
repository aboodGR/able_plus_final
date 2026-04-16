import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateProvider<bool>((ref){
return false;
});

final languageProvider = StateProvider<String>((ref) {
return 'en';
});
final ttsEnabledProvider = StateProvider<bool>((ref) {
  return true;
});
final colorblindModeProvider = StateProvider((ref){
  return false;
});
