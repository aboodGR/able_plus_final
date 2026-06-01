import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'PlaceDetailsScreen.dart';
import '../../../providers/places_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/AbleScaffold.dart';
import '../../../widgets/tts_wrapper.dart';
import '../../../widgets/VipBadge.dart';

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({
    super.key,
    required this.places,
    required this.initialLocation,
    this.selectedPlaceName,
  });

  final List<PlaceModel> places;
  final LatLng initialLocation;
  final String? selectedPlaceName;

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  PlaceModel? selectedPlace;
  String searchText = '';

  // Default fallback if user has no saved location
  static const LatLng ammanCenter = LatLng(31.9539, 35.9106);

  @override
  void initState() {
    super.initState();

    if (widget.selectedPlaceName != null) {
      for (final place in widget.places) {
        if (place.name == widget.selectedPlaceName) {
          selectedPlace = place;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<PlaceModel> get filteredPlaces {
    if (searchText.trim().isEmpty) return widget.places;

    final query = searchText.trim().toLowerCase();

    return widget.places.where((place) {
      final name = place.name.toLowerCase();
      final address = place.address.toLowerCase();

      return name.contains(query) || address.contains(query);
    }).toList();
  }

  void selectPlace(PlaceModel place) {
    setState(() {
      selectedPlace = place;
    });

    mapController.move(LatLng(place.latitude, place.longitude), 15);
  }

  void recenterMap() {
    setState(() {
      selectedPlace = null;
    });

    mapController.move(widget.initialLocation, 14);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);

    return AbleScaffold(
      title: l10n.mapTitle,
      currentIndex: 1,
      showBackButton: true,
      removeTopBodyPadding: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: widget.initialLocation,
                initialZoom: 14,
                onTap: (_, __) {
                  setState(() {
                    selectedPlace = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ableplus.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.initialLocation,
                      width: 90,
                      height: 90,
                      child: _MapMarker(
                        label: l10n.youMarker,
                        color: AbleTheme.primary(context),
                        selected: false,
                        onTap: recenterMap,
                      ),
                    ),
                    ...filteredPlaces.map((place) {
                      final isSelected =
                          selectedPlace != null &&
                          selectedPlace!.id == place.id;

                      return Marker(
                        point: LatLng(place.latitude, place.longitude),
                        width: isSelected ? 150 : 115,
                        height: 95,
                        child: _MapMarker(
                          label: place.name,
                          color: isSelected ? Colors.orange : accentColor,
                          selected: isSelected,
                          onTap: () => selectPlace(place),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          PositionedDirectional(
            top: 14,
            start: 16,
            end: 16,
            child: _SearchPanel(
              controller: searchController,
              searchText: searchText,
              titleColor: titleColor,
              mutedColor: mutedColor,
              accentColor: accentColor,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                  selectedPlace = null;
                });
              },
              onClear: () {
                searchController.clear();
                setState(() {
                  searchText = '';
                  selectedPlace = null;
                });
              },
            ),
          ),

          PositionedDirectional(
            end: 16,
            bottom: selectedPlace == null ? 225 : 265,
            child: SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                heroTag: 'full_map_recenter',
                onPressed: recenterMap,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          ),

          if (selectedPlace == null)
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: 100,
              child: _PlacesStrip(
                places: filteredPlaces,
                onPlaceTap: selectPlace,
              ),
            ),

          if (selectedPlace != null)
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: 100,
              child: _SelectedPlaceCard(
                place: selectedPlace!,
                onClose: () {
                  setState(() {
                    selectedPlace = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.searchText,
    required this.titleColor,
    required this.mutedColor,
    required this.accentColor,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String searchText;
  final Color titleColor;
  final Color mutedColor;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _GlassBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TtsWrapper(
          text: l10n.searchPlaces,
          child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: titleColor),
          decoration: InputDecoration(
            icon: Icon(Icons.search_rounded, color: accentColor),
            hintText: l10n.searchPlaces,
            hintStyle: TextStyle(color: mutedColor),
            border: InputBorder.none,
            suffixIcon: searchText.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: Icon(Icons.close_rounded, color: mutedColor),
                  ),
          ),
        ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = AbleTheme.textPrimary(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: color,
            size: selected ? 42 : 34,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AbleTheme.panelFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : AbleTheme.glassBorder(context),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacesStrip extends StatelessWidget {
  const _PlacesStrip({required this.places, required this.onPlaceTap});

  final List<PlaceModel> places;
  final void Function(PlaceModel place) onPlaceTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);

    if (places.isEmpty) {
      return _GlassBox(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: TtsWrapper(
            text: l10n.noPlacesFound,
            child: Text(l10n.noPlacesFound, style: TextStyle(color: mutedColor)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final place = places[index];

          return TtsWrapper(
            text: [
              place.name,
              place.address,
              (l10n.localeName == 'ar' ? 'التقييم ' : 'Rating ') +
                  place.rating.toStringAsFixed(1),
            ].where((p) => p.trim().isNotEmpty).join('. '),
            child: GestureDetector(
            onTap: () => onPlaceTap(place),
            child: VipGoldFrame(
              isVip: place.isVip,
              child: _GlassBox(
              width: 250,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AbleTheme.iconBubble(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.place_outlined, color: accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                          Expanded(child: Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w900,
                            ),
                          )),
                          if (place.isVip) ...[const SizedBox(width: 5), const VipBadge(compact: true)],
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: mutedColor, fontSize: 12),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                place.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 17,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({required this.place, required this.onClose});

  final PlaceModel place;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);

    final featureText = place.accessibilityFeatures.isEmpty
        ? l10n.accessibilityInfoPending
        : place.accessibilityFeatures.join(' • ');

    return VipGoldFrame(
      isVip: place.isVip,
      child: TtsWrapper(
      text: [
        place.name,
        place.address,
        (l10n.localeName == 'ar' ? 'التقييم ' : 'Rating ') +
            place.rating.toStringAsFixed(1),
        featureText,
      ].where((p) => p.trim().isNotEmpty).join('. '),
      child: _GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AbleTheme.iconBubble(context),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.place_outlined,
                    color: accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (place.isVip) ...[
                        const SizedBox(height: 5),
                        const VipBadge(compact: true),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: mutedColor),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    featureText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceDetailsScreen(place: place),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded),
                label: Text(l10n.viewDetails),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  const _GlassBox({required this.child, this.width});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AbleTheme.glassCard(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: child,
        ),
      ),
    );
  }
}