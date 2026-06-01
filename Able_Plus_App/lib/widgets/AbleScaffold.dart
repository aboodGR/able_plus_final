import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/services/tts_service.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final unreadMessagesCountProvider = StreamProvider<int>((ref) async* {
  final viewer = await ref.watch(viewerProvider.future);
  if (viewer == null) {
    yield 0;
    return;
  }

  final supabase = Supabase.instance.client;
  final currentAuthId = supabase.auth.currentUser?.id;

  final conversations = await supabase
      .from('conversations')
      .select('id, deleted_by')
      .or(
        'and(participant_a_id.eq.${viewer.id},participant_a_type.eq.${viewer.role}),'
        'and(participant_b_id.eq.${viewer.id},participant_b_type.eq.${viewer.role})',
      );

  final conversationIds = <String>{};

  for (final conv in conversations) {
    final convId = conv['id']?.toString() ?? '';
    if (convId.isEmpty) continue;

    final deletedByRaw = conv['deleted_by'];
    if (deletedByRaw != null) {
      final deletedBy = List<dynamic>.from(deletedByRaw as List);
      final hiddenForMe = deletedBy.any((id) {
        final value = id?.toString();
        return value == viewer.id || value == currentAuthId;
      });
      if (hiddenForMe) continue;
    }

    conversationIds.add(convId);
  }

  if (conversationIds.isEmpty) {
    yield 0;
    return;
  }

  yield* supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('is_seen', false)
      .map((rows) {
    return rows.where((row) {
      final conversationId = row['conversation_id']?.toString() ?? '';
      final senderId = row['sender_id']?.toString() ?? '';
      return conversationIds.contains(conversationId) && senderId != viewer.id;
    }).length;
  });
});


class AbleScaffold extends ConsumerWidget {
  const AbleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentIndex = 0,
    this.actions,
    this.floatingActionButton,
    this.showDrawer = false,
    this.titleWidget,
    this.removeTopBodyPadding = false,
    this.showBackButton = false,
  });

  final String title;
  final Widget body;
  final Widget? titleWidget;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showDrawer;
  final bool removeTopBodyPadding;
  final bool showBackButton;

  // ── زر Leading (Back / Menu) مع TTS ──
  Widget? _buildLeading(BuildContext context, WidgetRef ref) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final l10n = AppLocalizations.of(context);
    final isAr = l10n?.localeName == 'ar';

    // ── تقرأ النص المُمرّر (مش ثابت على "Back") ──
    void speakText(String text) {
      final ttsEnabled = ref.read(ttsEnabledProvider);
      if (!ttsEnabled) return;
      TtsService.instance.speak(text, enabled: true);
    }

    // ── Hover (ويب/ديسكتوب) أو Long Press (موبايل) يقرأ النص الخاص بالزر ──
    Widget wrapWithTts(Widget button, String label) {
      if (kIsWeb || _isDesktop) {
        return MouseRegion(onEnter: (_) => speakText(label), child: button);
      }
      return GestureDetector(onLongPress: () => speakText(label), child: button);
    }

    if (showBackButton) {
      return wrapWithTts(
        IconButton(
          tooltip: isAr ? 'رجوع' : 'Back',
          icon: Transform.flip(
            flipX: isRtl,
            child: const Icon(Icons.arrow_back_rounded),
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        isAr ? 'رجوع' : 'Back',
      );
    }

    if (showDrawer) {
      return Builder(
        builder: (innerContext) => wrapWithTts(
          IconButton(
            tooltip: isAr ? 'القائمة' : 'Menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
          ),
          isAr ? 'القائمة' : 'Menu',
        ),
      );
    }

    if (Navigator.of(context).canPop()) {
      return wrapWithTts(
        IconButton(
          tooltip: isAr ? 'رجوع' : 'Back',
          icon: Transform.flip(
            flipX: isRtl,
            child: const Icon(Icons.arrow_back_rounded),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        isAr ? 'رجوع' : 'Back',
      );
    }

    return null;
  }

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AbleTheme.isDark(context);
    final l10n = AppLocalizations.of(context);
    final isAr = l10n?.localeName == 'ar';

    // ── يقرأ عنوان الـ AppBar ──
    void speakTitle() {
      final ttsEnabled = ref.read(ttsEnabledProvider);
      if (!ttsEnabled) return;
      // "Able+" تُنطق "Able Plus" حتى ما يبلعها المحرك
      final spoken = title.trim() == 'Able+'
          ? (isAr ? 'أيبل بلَس' : 'Able Plus')
          : title;
      if (spoken.trim().isEmpty) return;
      TtsService.instance.speak(spoken, enabled: true);
    }

    // ── العنوان ملفوف بـ Hover (ويب) أو Long Press (موبايل) ──
    Widget buildTitle() {
      final inner = titleWidget ?? Text(title);
      if (kIsWeb || _isDesktop) {
        return MouseRegion(onEnter: (_) => speakTitle(), child: inner);
      }
      return GestureDetector(onLongPress: speakTitle, child: inner);
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      drawer: showDrawer ? const _AppDrawer() : null,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _buildLeading(context, ref),
        title: buildTitle(),
        centerTitle: true,
        actions: actions,
        backgroundColor: isDark
            ? const Color(0x99101828)
            : Colors.white.withOpacity(0.55),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(AbleTheme.backgroundAsset(context), fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: AbleTheme.screenOverlay(context)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: removeTopBodyPadding ? 0 : kToolbarHeight + 8),
              child: SizedBox(width: double.infinity, height: double.infinity, child: body),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(currentIndex: currentIndex),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AbleTheme.isDark(context);
    final l10n = AppLocalizations.of(context);
    final selectedColor = isDark ? AbleColors.darkSecondary : AbleColors.lightPrimary;
    final unselectedColor = AbleTheme.textMuted(context);
    final centerBubble = AbleTheme.primary(context);
    final activeBubble = isDark
        ? AbleColors.darkSecondary.withOpacity(0.16)
        : AbleColors.lightPrimary.withOpacity(0.14);
    final unreadMessagesAsync = ref.watch(unreadMessagesCountProvider);
    final unreadMessages = unreadMessagesAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    // ── يقرأ اسم زر التنقّل ──
    void speakLabel(String label) {
      final ttsEnabled = ref.read(ttsEnabledProvider);
      if (!ttsEnabled || label.trim().isEmpty) return;
      TtsService.instance.speak(label, enabled: true);
    }

    // ── route, icon, label لكل زر ──
    final items = [
      ('/home', Icons.home_rounded, l10n?.home ?? 'Home'),
      ('/home/map', Icons.location_on_outlined, l10n?.map ?? 'Map'),
      ('/home/create-post', Icons.add_rounded, l10n?.createPost ?? 'Create Post'),
      ('/home/messages', Icons.chat_bubble_outline_rounded, l10n?.messages ?? 'Messages'),
      ('/home/profile/currentUser', Icons.person_outline_rounded, l10n?.profile ?? 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AbleTheme.glassCard(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AbleTheme.glassBorder(context)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.30) : const Color(0x16000000),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isCenter = index == 2;
                final isSelected = index == currentIndex;
                final route = items[index].$1;
                final icon = items[index].$2;
                final label = items[index].$3;

                final button = InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    if (isCenter) {
                      final created = await context.push<bool>(route);
                      if (context.mounted) {
                        final container = ProviderScope.containerOf(context);
                        container.invalidate(postsProvider);
                      }
                      if (created == true && context.mounted) context.go('/home');
                      return;
                    }

                    if (isSelected) return;
                    if (!context.mounted) return;

                    await context.push(route);

                    if (context.mounted) {
                      ref.invalidate(unreadMessagesCountProvider);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isCenter ? 60 : 44,
                    height: isCenter ? 60 : 44,
                    decoration: BoxDecoration(
                      color: isCenter ? centerBubble : isSelected ? activeBubble : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          icon,
                          size: isCenter ? 32 : 23,
                          color: isCenter
                              ? Colors.white
                              : isSelected
                                  ? selectedColor
                                  : unselectedColor,
                        ),
                        if (index == 3 && unreadMessages > 0)
                          PositionedDirectional(
                            top: 5,
                            end: 4,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AbleColors.danger,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: AbleTheme.glassCard(context),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unreadMessages > 99
                                    ? '99+'
                                    : unreadMessages.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );

                // ── Hover (ويب/ديسكتوب) أو Long Press (موبايل) يقرأ اسم الزر ──
                final tooltipped = Tooltip(message: label, child: button);
                if (kIsWeb || _isDesktop) {
                  return MouseRegion(
                    onEnter: (_) => speakLabel(label),
                    child: tooltipped,
                  );
                }
                return GestureDetector(
                  onLongPress: () => speakLabel(label),
                  child: tooltipped,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final viewerAsync = ref.watch(viewerProvider);
    final viewerRole = viewerAsync.valueOrNull?.role;
    final canUseVip = viewerRole == 'business' || viewerRole == 'tutor' || viewerRole == 'charity';
    final vipLabel = l10n.localeName == 'ar' ? 'عضوية VIP' : 'VIP Membership';

    // ── يقرأ نص عنصر القائمة (Hover ويب / Long Press موبايل) ──
    void speak(String label) {
      final ttsEnabled = ref.read(ttsEnabledProvider);
      if (!ttsEnabled || label.trim().isEmpty) return;
      TtsService.instance.speak(label, enabled: true);
    }

    Widget ttsWrap(Widget child, String label) {
      if (kIsWeb || _isDesktop) {
        return MouseRegion(onEnter: (_) => speak(label), child: child);
      }
      return GestureDetector(onLongPress: () => speak(label), child: child);
    }

    final menuItems = [
      if (canUseVip) (vipLabel, Icons.workspace_premium_rounded, '/home/vip'),
      (l10n.myActivity, Icons.history_rounded, '/home/my-activity'),
      (l10n.support, Icons.volunteer_activism_outlined, '/home/support'),
      (l10n.aboutUs, Icons.info_outline_rounded, '/home/aboutus'),
      (l10n.settings, Icons.settings_outlined, '/home/settings'),
    ];

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF182437) : Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              viewerAsync.when(
                data: (viewer) {
                  final displayName = viewer?.displayName ?? 'User';
                  final username = viewer?.username;
                  final avatarUrl = viewer?.profileImage;
                  return ttsWrap(
                    Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor.withOpacity(0.15), border: Border.all(color: accentColor.withOpacity(0.3), width: 2)),
                          clipBehavior: Clip.antiAlias,
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _DefaultAvatar(color: accentColor))
                              : _DefaultAvatar(color: accentColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(username != null && username.isNotEmpty ? '@$username' : '@user', style: TextStyle(color: mutedColor, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    username != null && username.isNotEmpty
                        ? '$displayName. @$username'
                        : displayName,
                  );
                },
                loading: () => Row(children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor.withOpacity(0.15), border: Border.all(color: accentColor.withOpacity(0.3), width: 2)), child: _DefaultAvatar(color: accentColor)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(height: 14, width: 120, decoration: BoxDecoration(color: mutedColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 80, decoration: BoxDecoration(color: mutedColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4))),
                  ])),
                ]),
                error: (_, __) => Row(children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor.withOpacity(0.15), border: Border.all(color: accentColor.withOpacity(0.3), width: 2)), child: _DefaultAvatar(color: accentColor)),
                  const SizedBox(width: 14),
                  Expanded(child: Text('User', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor))),
                ]),
              ),
              const SizedBox(height: 24),
              Divider(color: AbleTheme.glassBorder(context), height: 1),
              const SizedBox(height: 16),
              ...menuItems.map((item) => ttsWrap(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: accentColor.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Icon(item.$2, color: accentColor, size: 20)),
                  title: Text(item.$1, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                  trailing: Icon(isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: mutedColor, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () { Navigator.pop(context); context.push(item.$3); },
                ),
                item.$1,
              )),
              const Spacer(),
              Divider(color: AbleTheme.glassBorder(context), height: 1),
              const SizedBox(height: 8),
              ttsWrap(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AbleColors.danger.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout_rounded, color: AbleColors.danger, size: 20)),
                  title: Text(l10n.logOut, style: const TextStyle(color: AbleColors.danger, fontWeight: FontWeight.w500)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.logOut),
                        content: Text(l10n.logOutConfirm),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.logOut, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    try {
                      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      context.go('/login');
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
                    }
                  },
                ),
                l10n.logOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.person_rounded, color: color, size: 30);
  }
}