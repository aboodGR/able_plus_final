import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/screens/Home/map/FullMapScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/places_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/AbleScaffold.dart';
import '../../../widgets/tts_wrapper.dart';
import '../../../widgets/VipBadge.dart';

/// Loads the *current logged-in user's* saved lat/long from whichever
/// table they belong to. Falls back to Amman center if they have none.
final currentUserLocationProvider = FutureProvider<LatLng>((ref) async {
  const fallback = LatLng(31.9539, 35.9106); // Amman center

  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return fallback;

  // Try each table in turn (only one will match).
  for (final table in ['clients', 'tutors', 'businesses', 'charities']) {
    try {
      final row = await supabase
          .from(table)
          .select('latitude, longitude')
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        final lat = row['latitude'];
        final lng = row['longitude'];
        if (lat != null && lng != null) {
          return LatLng((lat as num).toDouble(), (lng as num).toDouble());
        }
        // User exists in this table but has no GPS saved — stop and fall back.
        break;
      }
    } catch (_) {
      // Try next table.
    }
  }

  return fallback;
});

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final placesAsync = ref.watch(placesProvider);
    final userLocationAsync = ref.watch(currentUserLocationProvider);

    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);

    return AbleScaffold(
      title: l10n.nearbyPlaces,
      currentIndex: 1,
      body: placesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '${l10n.error}: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: titleColor),
            ),
          ),
        ),
        data: (items) {
          final userLocation = userLocationAsync.maybeWhen(
            data: (loc) => loc,
            orElse: () => const LatLng(31.9539, 35.9106),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              TtsWrapper(
                text: l10n.mapNearbyHeading,
                child: Text(
                  l10n.mapNearbyHeading,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TtsWrapper(
                text: l10n.mapNearbySubtitle,
                child: Text(
                  l10n.mapNearbySubtitle,
                  style: TextStyle(color: mutedColor, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // ================= SMALL MAP CARD =================
              SizedBox(
                height: 280,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AbleTheme.glassCard(context),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AbleTheme.glassBorder(context),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: userLocation,
                                  initialZoom: 13,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.ableplus.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: userLocation,
                                        width: 80,
                                        height: 80,
                                        child: _MapMarker(
                                          label: l10n.youMarker,
                                          color: AbleTheme.primary(context),
                                        ),
                                      ),
                                      ...items.map(
                                        (place) => Marker(
                                          point: LatLng(
                                            place.latitude,
                                            place.longitude,
                                          ),
                                          width: 110,
                                          height: 80,
                                          child: _MapMarker(
                                            label: place.name,
                                            color: place.isVip ? const Color(0xFFD99A16) : accentColor,
                                          ),
                                        ),
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

                    // ================= OPEN FULL MAP BUTTON =================
                    PositionedDirectional(
                      top: 16,
                      end: 16,
                      child: SizedBox(
                        width: 110,
                        height: 42,
                        child: TtsWrapper(
                          text: l10n.openMap,
                          child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullMapScreen(
                                  places: items,
                                  initialLocation: userLocation,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fullscreen_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(l10n.openMap),
                            ],
                          ),
                        ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TtsWrapper(
                text: l10n.suggestedPlaces,
                child: Text(
                  l10n.suggestedPlaces,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (items.isEmpty)
                TtsWrapper(
                  text: l10n.noPlacesFoundYet,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        l10n.noPlacesFoundYet,
                        style: TextStyle(color: mutedColor),
                      ),
                    ),
                  ),
                )
              else
                ...items.map(
                  (place) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TtsWrapper(
                      text: [
                        place.name,
                        place.address,
                        place.accessibilityFeatures.isEmpty
                            ? l10n.accessibilityInfoPending
                            : place.accessibilityFeatures.join(', '),
                        (l10n.localeName == 'ar' ? 'التقييم ' : 'Rating ') +
                            place.rating.toStringAsFixed(1),
                      ].where((p) => p.trim().isNotEmpty).join('. '),
                      child: VipGoldFrame(
                      isVip: place.isVip,
                      child: Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullMapScreen(
                                places: items,
                                initialLocation: LatLng(
                                  place.latitude,
                                  place.longitude,
                                ),
                                selectedPlaceName: place.name,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.all(14),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AbleTheme.iconBubble(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.place_outlined, color: accentColor),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(
                          place.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        )),
                        if (place.isVip) ...[
                          const SizedBox(width: 6),
                          const VipBadge(compact: true),
                        ],
                      ],
                    ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${place.address}\n${place.accessibilityFeatures.isEmpty ? l10n.accessibilityInfoPending : place.accessibilityFeatures.join(' • ')}',
                            style: TextStyle(color: mutedColor, height: 1.4),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(Icons.star_rounded, color: Colors.amber),
                          ],
                        ),
                      ),
                    ),
                    ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final titleColor = AbleTheme.textPrimary(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_rounded, color: color, size: 34),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AbleTheme.panelFill(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}