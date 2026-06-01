import 'dart:ui';

import 'package:ableplusproject/Models/BusinessModel.dart';
import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/screens/Home/businesses/businesses_screen.dart'
    show accessibilityCatalog, accessibilityLabel;
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:ableplusproject/widgets/VipBadge.dart';
import 'package:flutter/material.dart';

class BusinessDetailScreen extends StatelessWidget {
  const BusinessDetailScreen({super.key, required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accent = AbleTheme.accent(context);

    // ── النص المنطوق لكل تفاصيل المكان ──
    final isAr = l10n.localeName == 'ar';
    final displayName =
        business.fullName.isEmpty ? business.username : business.fullName;
    final ratingText = business.ratingCount > 0
        ? (isAr
            ? 'التقييم ${business.avgRating.toStringAsFixed(1)} من ${business.ratingCount}'
            : 'Rating ${business.avgRating.toStringAsFixed(1)} from ${business.ratingCount}')
        : l10n.noRatingsYet;
    final spokenParts = <String>[
      displayName,
      '@${business.username}',
      ratingText,
      if (business.distanceKm != null)
        l10n.kmAway(business.distanceKm!.toStringAsFixed(1)),
      if (business.location.trim().isNotEmpty) business.location,
      if (business.description != null && business.description!.isNotEmpty)
        business.description!,
    ];
    if (business.accessibilityFeatures.isNotEmpty) {
      spokenParts.add(l10n.accessibility);
      spokenParts.addAll(
        business.accessibilityFeatures.map((f) => accessibilityLabel(l10n, f)),
      );
    }
    final spokenText =
        spokenParts.where((p) => p.trim().isNotEmpty).join('. ');

    return AbleScaffold(
      title: business.fullName.isEmpty ? business.username : business.fullName,
      currentIndex: 0,
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          VipGoldFrame(
            isVip: business.isVip,
            child: TtsWrapper(
            text: spokenText,
            child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AbleTheme.iconBubble(context),
                              borderRadius: BorderRadius.circular(16),
                              image: business.profileImage != null &&
                                      business.profileImage!.isNotEmpty
                                  ? DecorationImage(
                                      image:
                                          NetworkImage(business.profileImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (business.profileImage == null ||
                                    business.profileImage!.isEmpty)
                                ? Icon(Icons.storefront_rounded,
                                    color: accent, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business.fullName.isEmpty
                                      ? business.username
                                      : business.fullName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                                if (business.isVip) ...[
                                  const SizedBox(height: 5),
                                  const VipBadge(compact: true),
                                ],
                                Text(
                                  '@${business.username}',
                                  style: TextStyle(
                                      color: mutedColor, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: AbleColors.warning, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            business.ratingCount > 0
                                ? '${business.avgRating.toStringAsFixed(1)} (${business.ratingCount})'
                                : l10n.noRatingsYet,
                            style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (business.distanceKm != null)
                            Text(
                              l10n.kmAway(
                                  business.distanceKm!.toStringAsFixed(1)),
                              style: TextStyle(
                                  color: accent, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              color: mutedColor, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              business.location,
                              style: TextStyle(color: mutedColor),
                            ),
                          ),
                        ],
                      ),
                      if (business.description != null &&
                          business.description!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          business.description!,
                          style: TextStyle(color: titleColor, height: 1.5),
                        ),
                      ],
                      if (business.accessibilityFeatures.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          l10n.accessibility,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: business.accessibilityFeatures.map((f) {
                            final icon =
                                accessibilityCatalog[f] ?? Icons.check_rounded;
                            final label = accessibilityLabel(l10n, f);
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
                                  Icon(
                                    icon,
                                    color: accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                        color: titleColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}