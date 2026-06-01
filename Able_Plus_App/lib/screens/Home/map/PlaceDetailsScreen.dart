import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/places_provider.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:ableplusproject/widgets/VipBadge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================================
// Reviews provider — one query for ratings, one batched lookup for
// client display info (name + avatar). Family keyed by (placeId, kind).
// =====================================================================

class PlaceReviewRef {
  final String placeId;
  final String kind; // 'business' or 'charity'
  const PlaceReviewRef(this.placeId, this.kind);

  @override
  bool operator ==(Object other) =>
      other is PlaceReviewRef &&
      other.placeId == placeId &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(placeId, kind);
}

class PlaceReview {
  final String clientId;
  final double rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String displayName;
  final String? avatarUrl;

  const PlaceReview({
    required this.clientId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
    required this.displayName,
    this.avatarUrl,
  });
}

final placeReviewsProvider = FutureProvider.autoDispose
    .family<List<PlaceReview>, PlaceReviewRef>((ref, args) async {
  final supabase = Supabase.instance.client;
  final table = '${args.kind}_ratings';
  final fkCol = '${args.kind}_id';

  // Pull all rows for this place. We'll filter to comment-having ones below.
  final rows = await supabase
      .from(table)
      .select('client_id, rating, comment, created_at, updated_at')
      .eq(fkCol, args.placeId);

  if (rows.isEmpty) return const [];

  final clientIds = rows.map((r) => r['client_id'].toString()).toSet().toList();

  // Names from clients.
  final clientRows = await supabase
      .from('clients')
      .select('id, full_name, username')
      .inFilter('id', clientIds);

  final nameMap = <String, String>{};
  for (final c in clientRows) {
    final id = c['id'].toString();
    final full = c['full_name']?.toString() ?? '';
    final user = c['username']?.toString() ?? '';
    nameMap[id] = full.isNotEmpty ? full : (user.isNotEmpty ? user : 'User');
  }

  // Avatars from profiles.
  final profileRows = await supabase
      .from('profiles')
      .select('client_id, profile_pic_url')
      .inFilter('client_id', clientIds);

  final avatarMap = <String, String?>{};
  for (final p in profileRows) {
    avatarMap[p['client_id'].toString()] = p['profile_pic_url']?.toString();
  }

  final reviews = <PlaceReview>[];
  for (final r in rows) {
    final id = r['client_id'].toString();
    final comment = r['comment']?.toString();
    // Only surface rows with a comment as a "review".
    if (comment == null || comment.trim().isEmpty) continue;

    reviews.add(PlaceReview(
      clientId: id,
      rating: (r['rating'] as num?)?.toDouble() ?? 0,
      comment: comment,
      createdAt: r['created_at'] != null
          ? DateTime.tryParse(r['created_at'].toString())?.toLocal()
          : null,
      updatedAt: r['updated_at'] != null
          ? DateTime.tryParse(r['updated_at'].toString())?.toLocal()
          : null,
      displayName: nameMap[id] ?? 'User',
      avatarUrl: avatarMap[id],
    ));
  }

  // Newest first.
  reviews.sort((a, b) {
    final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });

  return reviews;
});

// =====================================================================
// Screen
// =====================================================================

class PlaceDetailsScreen extends ConsumerStatefulWidget {
  const PlaceDetailsScreen({super.key, required this.place});

  final PlaceModel place;

  @override
  ConsumerState<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends ConsumerState<PlaceDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final place = widget.place;
    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accent = AbleTheme.accent(context);
    final primary = AbleTheme.primary(context);

    final reviewsAsync = ref.watch(
      placeReviewsProvider(PlaceReviewRef(place.id, place.kind)),
    );
    final viewerAsync = ref.watch(viewerProvider);
    final viewer = viewerAsync.valueOrNull;
    final canWrite = viewer != null && viewer.role == 'client';

    const hasImage = false;

    return AbleScaffold(
      title: place.name,
      currentIndex: 1,
      showBackButton: true,
      removeTopBodyPadding: true,
      body: CustomScrollView(
        slivers: [
          // ============ HERO ============
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: place.isVip
                            ? const [Color(0xFF4B3305), Color(0xFFD99A16)]
                            : [primary.withOpacity(0.85), accent.withOpacity(0.65)],
                      ),
                    ),
                    child: hasImage
                        ? null
                        : Center(
                            child: Icon(
                              place.kind == 'charity'
                                  ? Icons.volunteer_activism_rounded
                                  : Icons.storefront_rounded,
                              size: 110,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                          stops: const [0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 20,
                    end: 20,
                    bottom: 20,
                    child: TtsWrapper(
                      text: [
                        place.kind == 'charity'
                            ? l10n.placeKindCharity
                            : l10n.placeKindBusiness,
                        place.name,
                        (l10n.localeName == 'ar' ? 'التقييم ' : 'Rating ') +
                            (place.rating > 0
                                ? place.rating.toStringAsFixed(1)
                                : l10n.ratingNew),
                        place.address,
                      ].where((p) => p.trim().isNotEmpty).join('. '),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Text(
                            place.kind == 'charity'
                                ? l10n.placeKindCharity
                                : l10n.placeKindBusiness,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (place.isVip) ...[
                          const SizedBox(height: 10),
                          const VipBadge(),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              place.rating > 0
                                  ? place.rating.toStringAsFixed(1)
                                  : l10n.ratingNew,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_outlined,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============ ACTION ROW ============
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TtsWrapper(
                        text: l10n.viewProfile,
                        child: ElevatedButton.icon(
                        onPressed: _openProfile,
                        icon: const Icon(Icons.person_outline_rounded),
                        label: Text(
                          l10n.viewProfile,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TtsWrapper(
                    text: l10n.directionsComingSoon,
                    child: _IconAction(
                      icon: Icons.directions_rounded,
                      onTap: _openDirections,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TtsWrapper(
                    text: l10n.shareComingSoon,
                    child: _IconAction(
                      icon: Icons.share_outlined,
                      onTap: _sharePlace,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============ ACCESSIBILITY ============
          if (place.accessibilityFeatures.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: TtsWrapper(
                  text: '${l10n.accessibility}. ${place.accessibilityFeatures.join(', ')}',
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accessibility,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: place.accessibilityFeatures.map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AbleTheme.iconBubble(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  color: accent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                f,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  ),
                ),
              ),
            ),

          // ============ REVIEWS HEADER ============
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  Text(
                    l10n.reviews,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  reviewsAsync.when(
                    data: (list) => Text(
                      list.length.toString(),
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const Spacer(),
                  if (canWrite)
                    TextButton.icon(
                      onPressed: () => _openWriteReviewSheet(viewer!),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(l10n.writeReviewShort),
                    ),
                ],
              ),
            ),
          ),

          // ============ REVIEWS LIST ============
          reviewsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.couldNotLoadReviews(e.toString()),
                  style: TextStyle(color: mutedColor),
                ),
              ),
            ),
            data: (reviews) {
              if (reviews.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AbleTheme.glassCard(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AbleTheme.glassBorder(context)),
                          ),
                          child: TtsWrapper(
                            text: canWrite
                                ? l10n.noReviewsBeFirst
                                : l10n.noReviewsYet,
                            child: Text(
                              canWrite
                                  ? l10n.noReviewsBeFirst
                                  : l10n.noReviewsYet,
                              style: TextStyle(color: mutedColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverList.builder(
                itemCount: reviews.length + 1,
                itemBuilder: (context, i) {
                  if (i == reviews.length) return const SizedBox(height: 110);
                  return _ReviewCard(review: reviews[i]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ===================== ACTIONS =====================

  void _openProfile() {
    final place = widget.place;
    context.push('/profile/${place.kind}/${place.id}');
  }

  void _openDirections() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.directionsComingSoon),
      ),
    );
  }

  void _sharePlace() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shareComingSoon)),
    );
  }

  Future<void> _openWriteReviewSheet(AppViewer viewer) async {
    final l10n = AppLocalizations.of(context)!;
    final place = widget.place;
    final supabase = Supabase.instance.client;
    final table = '${place.kind}_ratings';
    final fkCol = '${place.kind}_id';

    // Preload existing review (if any) so we edit instead of starting blank.
    final existing = await supabase
        .from(table)
        .select('rating, comment')
        .eq('client_id', viewer.id)
        .eq(fkCol, place.id)
        .maybeSingle();

    double selectedRating =
        (existing?['rating'] as num?)?.toDouble() ?? 5;
    final commentCtrl = TextEditingController(
      text: existing?['comment']?.toString() ?? '',
    );

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          bool submitting = false;

          Future<void> submit() async {
            setSheetState(() => submitting = true);
            try {
              // UPDATE first, INSERT if no row. Keeps comment intact whether
              // the row started as rating-only (from profile.dart) or new.
              final updated = await supabase
                  .from(table)
                  .update({
                    'rating': selectedRating,
                    'comment': commentCtrl.text.trim().isEmpty
                        ? null
                        : commentCtrl.text.trim(),
                  })
                  .eq('client_id', viewer.id)
                  .eq(fkCol, place.id)
                  .select('rating');

              if (updated.isEmpty) {
                await supabase.from(table).insert({
                  'client_id': viewer.id,
                  fkCol: place.id,
                  'rating': selectedRating,
                  if (commentCtrl.text.trim().isNotEmpty)
                    'comment': commentCtrl.text.trim(),
                });
              }

              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);

              ref.invalidate(
                placeReviewsProvider(
                  PlaceReviewRef(place.id, place.kind),
                ),
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.thanksForReview)),
              );
            } catch (e) {
              if (!sheetContext.mounted) return;
              setSheetState(() => submitting = false);
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(content: Text(l10n.couldNotSaveReview(e.toString()))),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AbleTheme.isDark(context)
                    ? const Color(0xFF182437)
                    : Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Text(
                    existing == null
                        ? l10n.writeReview
                        : l10n.editYourReview,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final value = (i + 1).toDouble();
                      final filled = value <= selectedRating;
                      return IconButton(
                        onPressed: submitting
                            ? null
                            : () =>
                                setSheetState(() => selectedRating = value),
                        icon: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 34,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentCtrl,
                    minLines: 3,
                    maxLines: 6,
                    enabled: !submitting,
                    decoration: InputDecoration(
                      hintText: l10n.reviewCommentHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: submitting ? null : submit,
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(submitting ? l10n.saving : l10n.submit),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AbleTheme.accent(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AbleTheme.iconBubble(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AbleTheme.glassBorder(context)),
        ),
        child: Icon(icon, color: accent, size: 22),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final PlaceReview review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accent = AbleTheme.accent(context);

    final initial = review.displayName.isNotEmpty
        ? review.displayName[0].toUpperCase()
        : 'U';

    final isAr = l10n.localeName == 'ar';
    final spokenText = [
      review.displayName,
      _relativeTime(l10n, review.updatedAt ?? review.createdAt),
      (isAr ? 'التقييم ' : 'Rating ') + review.rating.toStringAsFixed(0),
      if (review.comment != null && review.comment!.isNotEmpty) review.comment!,
    ].where((p) => p.trim().isNotEmpty).join('. ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TtsWrapper(
        text: spokenText,
        child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AbleTheme.glassCard(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AbleTheme.glassBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: accent.withOpacity(0.18),
                      backgroundImage:
                          review.avatarUrl != null && review.avatarUrl!.isNotEmpty
                              ? NetworkImage(review.avatarUrl!)
                              : null,
                      child:
                          review.avatarUrl == null || review.avatarUrl!.isEmpty
                              ? Text(
                                  initial,
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.displayName,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _relativeTime(
                                l10n, review.updatedAt ?? review.createdAt),
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: i < review.rating.round()
                              ? Colors.amber
                              : mutedColor,
                        );
                      }),
                    ),
                  ],
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    review.comment!,
                    style: TextStyle(
                      color: titleColor.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  String _relativeTime(AppLocalizations l10n, DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    if (diff.inDays < 30) return l10n.weeksAgo((diff.inDays / 7).floor());
    if (diff.inDays < 365) return l10n.monthsAgo((diff.inDays / 30).floor());
    return l10n.yearsAgo((diff.inDays / 365).floor());
  }
}