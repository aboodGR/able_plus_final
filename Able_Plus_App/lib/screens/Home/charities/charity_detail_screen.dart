import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/Models/CharityModel.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:flutter/material.dart';

class CharityDetailScreen extends StatelessWidget {
  const CharityDetailScreen({super.key, required this.charity});

  final CharityModel charity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accent = AbleTheme.accent(context);

    final spokenParts = <String>[
      charity.displayName,
      '@${charity.username}',
      charity.location.isEmpty ? l10n.noLocation : charity.location,
      if (charity.distanceKm != null)
        '${charity.distanceKm!.toStringAsFixed(1)} km',
    ];
    final spokenText =
        spokenParts.where((p) => p.trim().isNotEmpty).join('. ');

    return AbleScaffold(
      title: charity.displayName,
      currentIndex: 0,
      showBackButton: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              TtsWrapper(
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
                                    image: charity.profileImage != null &&
                                            charity.profileImage!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                charity.profileImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (charity.profileImage == null ||
                                          charity.profileImage!.isEmpty)
                                      ? Icon(Icons.volunteer_activism_rounded,
                                          color: accent, size: 28)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        charity.displayName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: titleColor,
                                        ),
                                      ),
                                      Text(
                                        '@${charity.username}',
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
                                Icon(Icons.place_outlined,
                                    color: mutedColor, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    charity.location.isEmpty
                                        ? l10n.noLocation
                                        : charity.location,
                                    style: TextStyle(color: mutedColor),
                                  ),
                                ),
                                if (charity.distanceKm != null)
                                  Text(
                                    '${charity.distanceKm!.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}