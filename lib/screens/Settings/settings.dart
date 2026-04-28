import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget{
  const SettingsScreen({super.key});

  Widget build(BuildContext context, WidgetRef ref){
    final isDark = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final tts = ref.watch(ttsEnabledProvider);
    final colorBlind = ref.watch(colorblindModeProvider);

    return AbleScaffold(
      title: 'Settings',
      currentIndex: 4,
       body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            child: Column( 
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: isDark,
                  onChanged: (value) => ref.read(themeProvider.notifier).state = value,
                ),
                ListTile(
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: language,
                    items:const [
                      DropdownMenuItem(value:'en', child: Text('English')),
                      DropdownMenuItem(value:'ar', child: Text('العربية')),
                    ],
                    onChanged: (value) => ref.read(languageProvider.notifier).state = value ?? 'en',
                  ),
                ),
                SwitchListTile(
                  title: const Text('Text to Speech'),
                  value: tts,
                  onChanged: (value) => ref.read(ttsEnabledProvider.notifier).state = value,
                ),
                SwitchListTile(
                  title: const Text('Color Blind Mode'),
                  value: colorBlind,
                  onChanged: (value) => ref.read(colorblindModeProvider.notifier).state = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),title: Text('Privacy Settings'),
                ),
                ListTile(
                  leading: Icon(Icons.history_rounded),title: Text('My activity'),
                ),
                
              ],
            ),
          ),
        ],
       ),
       );
  }
}