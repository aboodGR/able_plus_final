// OPTION A — Compact cards + visible feed preview
// Cards are smaller (horizontal list style), feed starts higher up.

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
  List<_QuickCardSpec> _tilesForRole(
      String? role, BuildContext context, AppLocalizations l10n) {
    final places = _QuickCardSpec(
        key: 'places',
        title: l10n.places,
        subtitle: l10n.verifiedAccessibility,
        icon: Icons.place_outlined,
        onTap: () => context.push('/home/places'));
    final tutors = _QuickCardSpec(
        key: 'tutors',
        title: l10n.tutors,
        subtitle: l10n.learningSupport,
        icon: Icons.school_outlined,
        onTap: () => context.push('/home/tutors'));
    final charities = _QuickCardSpec(
        key: 'charities',
        title: l10n.charities,
        subtitle: l10n.supportAndVolunteering,
        icon: Icons.volunteer_activism_outlined,
        onTap: () => context.push('/home/charities'));
    final community = _QuickCardSpec(
        key: 'Findandshare',
        title: l10n.findAndShare,
        subtitle: l10n.questionsAndUpdates,
        icon: Icons.forum_outlined,
        onTap: () => context.push('/home/Findandshare'));
    switch (role) {
      case 'business':
        return [places];
      case 'tutor':
        return [tutors];
      case 'charity':
        return [charities];
      case 'client':
      default:
        return [places, tutors, charities, community];
    }
  }

  @override
  void initState() {
    super.initState();
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
    final accentColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    final viewerRole =
        viewerAsync.maybeWhen(data: (v) => v?.role, orElse: () => null);
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
                final count =
                    unread.maybeWhen(data: (v) => v, orElse: () => 0);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded),
                    if (count > 0)
                      Positioned.directional(
                        textDirection: Directionality.of(context),
                        end: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          constraints: const BoxConstraints(
                              minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF101828)
                                    : Colors.white,
                                width: 1.5),
                          ),
                          child: Text(count > 99 ? '99+' : '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1)),
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
                final imageUrl = viewerAsync.maybeWhen(
                    data: (v) => v?.profileImage, orElse: () => null);
                return CircleAvatar(
                  radius: 14,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.10)
                      : const Color(0xFFE8F7FC),
                  backgroundImage:
                      imageUrl != null && imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Text('A',
                          style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12))
                      : null,
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
              // ── Compact horizontal cards ──
              _QuickCardsSection(tiles: tiles, lang: lang),
              const SizedBox(height: 16),

              // ── Feed Header ──
              TtsWrapper(
                text:
                    '${l10n.communityFeed}. ${(currentFilter == FeedFilter.following && viewerRole == 'client') ? l10n.postsFromFollowing : l10n.latestPosts}',
                child: Column(children: [
                  Text(l10n.communityFeed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: titleColor)),
                  const SizedBox(height: 4),
                  Text(
                    (currentFilter == FeedFilter.following &&
                            viewerRole == 'client')
                        ? l10n.postsFromFollowing
                        : l10n.latestPosts,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AbleColors.darkTextMuted
                            : AbleColors.lightTextMuted),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // ── Filter Chips ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TtsWrapper(
                    text: l10n.all,
                    child: _FilterChipButton(
                      label: l10n.all,
                      selected: currentFilter == FeedFilter.all,
                      onTap: () {
                        ref.read(feedFilterProvider.notifier).state =
                            FeedFilter.all;
                        ref.invalidate(postsProvider);
                      },
                    ),
                  ),
                  if (viewerRole == 'client') ...[
                    const SizedBox(width: 10),
                    TtsWrapper(
                      text: l10n.following,
                      child: _FilterChipButton(
                        label: l10n.following,
                        selected: currentFilter == FeedFilter.following,
                        onTap: () {
                          ref.read(feedFilterProvider.notifier).state =
                              FeedFilter.following;
                          ref.invalidate(postsProvider);
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Empty State ──
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white.withOpacity(0.75)),
                  ),
                  child: Column(children: [
                    Icon(Icons.forum_outlined,
                        size: 48, color: accentColor),
                    const SizedBox(height: 16),
                    Text(
                        currentFilter == FeedFilter.following
                            ? l10n.noFollowingPostsYet
                            : l10n.noPostsYet,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: titleColor)),
                    const SizedBox(height: 8),
                    Text(
                        currentFilter == FeedFilter.following
                            ? l10n.followToSeePosts
                            : l10n.createFirstPost,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDark
                                ? AbleColors.darkTextMuted
                                : AbleColors.lightTextMuted)),
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
              Text(l10n.somethingWentWrong,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: titleColor)),
              const SizedBox(height: 8),
              Text(error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isDark
                          ? AbleColors.darkTextMuted
                          : AbleColors.lightTextMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCardSpec {
  const _QuickCardSpec(
      {required this.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});
  final String key, title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

// ── Option A: compact 2-column grid with smaller cards ──
class _QuickCardsSection extends StatelessWidget {
  const _QuickCardsSection({required this.tiles, required this.lang});
  final List<_QuickCardSpec> tiles;
  final String lang;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    Widget wrap(_QuickCardSpec spec) => TtsWrapper(
          text: '${spec.title}: ${spec.subtitle}',
          child: _QuickCard.fromSpec(spec),
        );

    if (tiles.length == 1) {
      return SizedBox(height: 100, child: wrap(tiles.first));
    }

    if (tiles.length == 2) {
      return SizedBox(
        height: 100,
        child: Row(children: [
          Expanded(child: wrap(tiles[0])),
          const SizedBox(width: 10),
          Expanded(child: wrap(tiles[1])),
        ]),
      );
    }

    if (tiles.length == 3) {
      return Column(children: [
        SizedBox(
          height: 100,
          child: Row(children: [
            Expanded(child: wrap(tiles[0])),
            const SizedBox(width: 10),
            Expanded(child: wrap(tiles[1])),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(height: 100, child: wrap(tiles[2])),
      ]);
    }

    // 4 tiles — compact 2×2 grid with reduced aspect ratio
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7, // wider than tall → much shorter cards
      children: tiles.map(wrap).toList(),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);
    final primaryColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;
    final textColor =
        selected ? Colors.white : AbleTheme.textPrimary(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? primaryColor : AbleTheme.glassCard(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected
                  ? primaryColor
                  : AbleTheme.glassBorder(context)),
        ),
        child: Text(label,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});

  factory _QuickCard.fromSpec(_QuickCardSpec spec) => _QuickCard(
      title: spec.title,
      subtitle: spec.subtitle,
      icon: spec.icon,
      onTap: spec.onTap);

  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);
    final iconBg = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE8F7FC);
    final iconColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;
    final titleColor =
        isDark ? AbleColors.darkText : AbleColors.lightText;
    final subtitleColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: titleColor)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: subtitleColor)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: subtitleColor, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}