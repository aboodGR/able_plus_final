import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/notificationsProvider.dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/services/tts_service.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'postcard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  List<_QuickCardSpec> _tilesForRole(String? role, BuildContext context, AppLocalizations l10n) {
    final places = _QuickCardSpec(key: 'places', title: l10n.places, subtitle: l10n.verifiedAccessibility, icon: Icons.place_outlined, onTap: () => context.push('/home/places'));
    final tutors = _QuickCardSpec(key: 'tutors', title: l10n.tutors, subtitle: l10n.learningSupport, icon: Icons.school_outlined, onTap: () => context.push('/home/tutors'));
    final charities = _QuickCardSpec(key: 'charities', title: l10n.charities, subtitle: l10n.supportAndVolunteering, icon: Icons.volunteer_activism_outlined, onTap: () => context.push('/home/charities'));
    final community = _QuickCardSpec(key: 'Findandshare', title: l10n.findAndShare, subtitle: l10n.questionsAndUpdates, icon: Icons.forum_outlined, onTap: () => context.push('/home/Findandshare'));
    switch (role) {
      case 'business': return [places];
      case 'tutor': return [tutors];
      case 'charity': return [charities];
      case 'client':
      default: return [places, tutors, charities, community];
    }
  }

  @override
  void initState() {
    super.initState();
    // ── اقرأ محتوى الصفحة لما تفتح ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(ttsEnabledProvider)) return;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      final lang = ref.read(languageProvider).languageCode;
      final sep = lang == 'ar' ? '، ' : ', ';
      final appName = lang == 'ar' ? 'أيبل بلَس' : 'Able Plus';
      final text = [
        appName,
        l10n.communityFeed,
        l10n.places,
        l10n.tutors,
        l10n.charities,
        l10n.findAndShare,
      ].join(sep);
      TtsService.instance.speak(text, enabled: true, lang: lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(languageProvider).languageCode;
    final posts = ref.watch(postsProvider);
    final currentFilter = ref.watch(feedFilterProvider);
    final viewerAsync = ref.watch(viewerProvider);
    final isDark = AbleTheme.isDark(context);

    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final accentColor = isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    final viewerRole = viewerAsync.maybeWhen(data: (v) => v?.role, orElse: () => null);
    final tiles = _tilesForRole(viewerRole, context, l10n);

    return AbleScaffold(
      title: 'Able+',
      currentIndex: 0,
      showDrawer: true,
      actions: [
        TtsWrapper(
          text: l10n.notifications,
          child: IconButton(
          onPressed: () {
            context.push('/home/notifications');
            ref.invalidate(unreadNotificationsProvider);
          },
          icon: Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadNotificationsProvider);
              final count = unread.maybeWhen(data: (v) => v, orElse: () => 0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded),
                  if (count > 0)
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      end: -6, top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF101828) : Colors.white, width: 1.5),
                        ),
                        child: Text(count > 99 ? '99+' : '$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1.1)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        ),
        TtsWrapper(
          text: l10n.profile,
          child: IconButton(
          onPressed: () => context.push('/profile'),
          icon: Consumer(
            builder: (context, ref, _) {
              final viewerAsync = ref.watch(viewerProvider);
              final imageUrl = viewerAsync.maybeWhen(data: (v) => v?.profileImage, orElse: () => null);
              return CircleAvatar(
                radius: 14,
                backgroundColor: isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE8F7FC),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl == null || imageUrl.isEmpty ? Text('A', style: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 12)) : null,
              );
            },
          ),
        ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(postsProvider);
          await ref.read(postsProvider.future);
        },
        child: posts.when(
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // ── Quick Cards مع TTS ──
              _QuickCardsSection(tiles: tiles, lang: lang),
              const SizedBox(height: 24),

              // ── Feed Header ──
              TtsWrapper(
                text: '${l10n.communityFeed}. ${(currentFilter == FeedFilter.following && viewerRole == 'client') ? l10n.postsFromFollowing : l10n.latestPosts}',
                child: Column(children: [
                  Text(l10n.communityFeed, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: titleColor)),
                  const SizedBox(height: 6),
                  Text(
                    (currentFilter == FeedFilter.following && viewerRole == 'client') ? l10n.postsFromFollowing : l10n.latestPosts,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Filter Chips ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TtsWrapper(
                    text: l10n.all,
                    child: _FilterChipButton(
                      label: l10n.all,
                      selected: currentFilter == FeedFilter.all,
                      onTap: () { ref.read(feedFilterProvider.notifier).state = FeedFilter.all; ref.invalidate(postsProvider); },
                    ),
                  ),
                  if (viewerRole == 'client') ...[
                    const SizedBox(width: 10),
                    TtsWrapper(
                      text: l10n.following,
                      child: _FilterChipButton(
                        label: l10n.following,
                        selected: currentFilter == FeedFilter.following,
                        onTap: () { ref.read(feedFilterProvider.notifier).state = FeedFilter.following; ref.invalidate(postsProvider); },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              // ── Empty State ──
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.75)),
                  ),
                  child: Column(children: [
                    Icon(Icons.forum_outlined, size: 48, color: accentColor),
                    const SizedBox(height: 16),
                    Text(currentFilter == FeedFilter.following ? l10n.noFollowingPostsYet : l10n.noPostsYet, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: titleColor)),
                    const SizedBox(height: 8),
                    Text(currentFilter == FeedFilter.following ? l10n.followToSeePosts : l10n.createFirstPost, textAlign: TextAlign.center, style: TextStyle(color: isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted)),
                  ]),
                ),

              // ── Posts ──
              ...items.map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PostCard(post: post),
              )),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.somethingWentWrong, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: titleColor)),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center, style: TextStyle(color: isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCardSpec {
  const _QuickCardSpec({required this.key, required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String key, title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickCardsSection extends StatelessWidget {
  const _QuickCardsSection({required this.tiles, required this.lang});
  final List<_QuickCardSpec> tiles;
  final String lang;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    // ── كل كارد ملفوف بـ TtsWrapper ──
    Widget wrap(_QuickCardSpec spec, {bool centered = true, bool compact = false}) =>
        TtsWrapper(
          text: '${spec.title}: ${spec.subtitle}',
          child: _QuickCard.fromSpec(spec, centered: centered, compact: compact),
        );

    if (tiles.length == 1) return SizedBox(height: 160, child: wrap(tiles.first));

    if (tiles.length == 2) return SizedBox(
      height: 140,
      child: Row(children: [
        Expanded(child: wrap(tiles[0])),
        const SizedBox(width: 12),
        Expanded(child: wrap(tiles[1])),
      ]),
    );

    if (tiles.length == 3) return Column(children: [
      SizedBox(height: 140, child: Row(children: [
        Expanded(child: wrap(tiles[0])),
        const SizedBox(width: 12),
        Expanded(child: wrap(tiles[1])),
      ])),
      const SizedBox(height: 12),
      SizedBox(height: 120, child: wrap(tiles[2])),
    ]);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: tiles.map((s) => wrap(s, compact: true)).toList(),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);
    final primaryColor = isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;
    final textColor = selected ? Colors.white : AbleTheme.textPrimary(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryColor : AbleTheme.glassCard(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? primaryColor : AbleTheme.glassBorder(context)),
        ),
        child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.title, required this.subtitle, required this.icon, required this.onTap, this.centered = false, this.compact = false});

  factory _QuickCard.fromSpec(_QuickCardSpec spec, {bool centered = false, bool compact = false}) =>
      _QuickCard(title: spec.title, subtitle: spec.subtitle, icon: spec.icon, onTap: spec.onTap, centered: centered, compact: compact);

  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool centered, compact;

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);
    final iconBg = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE8F7FC);
    final iconColor = isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;
    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final subtitleColor = isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;
    final iconBoxSize = compact ? 44.0 : 56.0;
    final iconSize = compact ? 24.0 : 30.0;
    final titleSize = compact ? 14.0 : 18.0;
    final subtitleSize = compact ? 11.5 : 13.0;

    final stack = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(width: iconBoxSize, height: iconBoxSize, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(compact ? 14 : 18)), child: Icon(icon, color: iconColor, size: iconSize)),
        const SizedBox(height: 12),
        Text(title, textAlign: centered ? TextAlign.center : TextAlign.start, style: TextStyle(fontWeight: FontWeight.w700, color: titleColor, fontSize: titleSize)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: centered ? TextAlign.center : TextAlign.start, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: subtitleColor, fontSize: subtitleSize)),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Card(child: Padding(padding: EdgeInsets.all(compact ? 12 : 14), child: centered ? Center(child: stack) : stack)),
        ),
      ),
    );
  }
}