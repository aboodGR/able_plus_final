import 'dart:ui';

import 'package:ableplusproject/Models/BusinessModel.dart';
import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/businesses_provider.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:ableplusproject/widgets/VipBadge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

/// Catalogue of accessibility feature icons. Edit this single map to add more
/// options across the whole app. Labels are resolved via [accessibilityLabel]
/// so they stay localizable (a const map can't reference AppLocalizations).
const accessibilityCatalog = <String, IconData>{
  'wheelchair_access': Icons.accessible_rounded,
  'service_animal': Icons.pets_rounded,
  'sign_language': Icons.sign_language_rounded,
  'braille': Icons.menu_book_rounded,
  'sensory_friendly': Icons.spa_rounded,
  'accessible_parking': Icons.local_parking_rounded,
};

/// Localized human label for an accessibility feature key. Unknown keys fall
/// back to a prettified version of the key itself.
String accessibilityLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'wheelchair_access':
      return l10n.featureWheelchairAccess;
    case 'service_animal':
      return l10n.featureServiceAnimal;
    case 'sign_language':
      return l10n.featureSignLanguage;
    case 'braille':
      return l10n.featureBraille;
    case 'sensory_friendly':
      return l10n.featureSensoryFriendly;
    case 'accessible_parking':
      return l10n.featureAccessibleParking;
    default:
      return _pretty(key);
  }
}

class BusinessesScreen extends ConsumerStatefulWidget {
  const BusinessesScreen({super.key});

  @override
  ConsumerState<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends ConsumerState<BusinessesScreen> {
  final _searchController = TextEditingController();
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFetchLocation());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _maybeFetchLocation() async {
    if (_locationRequested) return;
    _locationRequested = true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;
      ref
          .read(businessFiltersProvider.notifier)
          .setUserLocation(pos.latitude, pos.longitude);
    } catch (_) {
      // Silently ignore — distance just won't be available.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = ref.watch(businessFiltersProvider);
    final businesses = ref.watch(businessesProvider);
    final categories = ref.watch(businessCategoriesProvider);
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);

    return AbleScaffold(
      title: l10n.places,
      currentIndex: 0,
      showBackButton: true,
      body: Column(
        children: [
          // Search + filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TtsWrapper(
                    text: l10n.searchBusinesses,
                    child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        ref.read(businessFiltersProvider.notifier).setQuery(v),
                    decoration: InputDecoration(
                      hintText: l10n.searchBusinesses,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: filters.query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(businessFiltersProvider.notifier)
                                    .setQuery('');
                              },
                            ),
                    ),
                  ),
                  ),
                ),
                const SizedBox(width: 10),
                TtsWrapper(
                  text: l10n.filters,
                  child: _IconBubbleButton(
                    icon: Icons.tune_rounded,
                    onTap: () => _openFilterSheet(context),
                    hasIndicator: _hasActiveFilters(filters),
                  ),
                ),
              ],
            ),
          ),

          // Category chips
          categories.when(
            data: (cats) => _CategoryChips(
              categories: cats,
              selected: filters.category,
              onSelect: (c) =>
                  ref.read(businessFiltersProvider.notifier).setCategory(c),
            ),
            loading: () => const SizedBox(height: 44),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // Active filter summary row
          if (_hasActiveFilters(filters))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TtsWrapper(
                      text: _filterSummary(l10n, filters),
                      child: Text(
                        _filterSummary(l10n, filters),
                        style: TextStyle(color: mutedColor, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(businessFiltersProvider.notifier).clearAll();
                    },
                    child: Text(l10n.clear),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: businesses.when(
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(
                    onRequest: () => _showRequestBusinessDialog(context),
                  );
                }
                return RefreshIndicator(
                  color: AbleTheme.primary(context),
                  onRefresh: () async => ref.invalidate(businessesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _BusinessCard(business: items[i]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '${l10n.couldNotLoadBusinesses}\n$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(BusinessFilters f) =>
      f.category != null ||
      f.maxDistanceKm != null ||
      f.sort != BusinessSort.highestRated ||
      f.query.isNotEmpty;

  String _filterSummary(AppLocalizations l10n, BusinessFilters f) {
    final parts = <String>[];
    if (f.category != null) parts.add(_pretty(f.category!));
    if (f.maxDistanceKm != null) {
      parts.add(l10n.withinKm(f.maxDistanceKm!.toStringAsFixed(0)));
    }
    parts.add(_sortLabel(l10n, f.sort));
    return parts.join(' · ');
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  void _showRequestBusinessDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.requestABusiness),
        content: Text(l10n.requestBusinessBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.requestThanks)),
              );
            },
            child: Text(l10n.submit),
          ),
        ],
      ),
    );
  }
}

String _sortLabel(AppLocalizations l10n, BusinessSort s) {
  switch (s) {
    case BusinessSort.highestRated:
      return l10n.sortTopRated;
    case BusinessSort.mostReviewed:
      return l10n.sortMostReviewed;
    case BusinessSort.closest:
      return l10n.sortClosest;
    case BusinessSort.alphabetical:
      return l10n.sortAlphabetical;
  }
}

String _pretty(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';

// ---------------------------------------------------------------------------
// Category chips
// ---------------------------------------------------------------------------

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _Chip(
              label: l10n.all,
              selected: selected == null,
              onTap: () => onSelect(null),
            );
          }
          final c = categories[i - 1];
          return _Chip(
            label: _pretty(c),
            selected: selected == c,
            onTap: () => onSelect(c),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selBg = AbleTheme.primary(context);
    final unselBg = AbleTheme.glassCard(context);
    final selText = Colors.white;
    final unselText = AbleTheme.textPrimary(context);

    return TtsWrapper(
      text: label,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selBg : unselBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? selBg
                  : AbleTheme.glassBorder(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? selText : unselText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _IconBubbleButton extends StatelessWidget {
  const _IconBubbleButton({
    required this.icon,
    required this.onTap,
    this.hasIndicator = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasIndicator;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AbleTheme.glassCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AbleTheme.accent(context), size: 22),
              if (hasIndicator)
                PositionedDirectional(
                  top: 10,
                  end: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AbleTheme.primary(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AbleTheme.glassCard(context),
                        width: 1.5,
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

// ---------------------------------------------------------------------------
// Business card
// ---------------------------------------------------------------------------

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accent = AbleTheme.accent(context);

    // ── النص المنطوق للبطاقة كاملة ──
    final isAr = l10n.localeName == 'ar';
    final displayName =
        business.fullName.isEmpty ? business.username : business.fullName;
    final spokenParts = <String>[
      displayName,
      '@${business.username}',
      if (business.ratingCount > 0)
        (isAr ? 'التقييم ${business.avgRating.toStringAsFixed(1)}' : 'Rating ${business.avgRating.toStringAsFixed(1)}'),
      if (business.location.trim().isNotEmpty) business.location,
      if (business.distanceKm != null)
        '${business.distanceKm!.toStringAsFixed(1)} km',
    ];
    if (business.accessibilityFeatures.isNotEmpty) {
      spokenParts.addAll(
        business.accessibilityFeatures
            .take(4)
            .map((f) => accessibilityLabel(l10n, f)),
      );
    }
    final spokenText =
        spokenParts.where((p) => p.trim().isNotEmpty).join('. ');

    return VipGoldFrame(
      isVip: business.isVip,
      child: TtsWrapper(
      text: spokenText,
      child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () =>
         context.push('/profile/business/${business.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AbleTheme.iconBubble(context),
                      borderRadius: BorderRadius.circular(16),
                      image: business.profileImage != null &&
                              business.profileImage!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(business.profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (business.profileImage == null ||
                            business.profileImage!.isEmpty)
                        ? Icon(Icons.storefront_rounded,
                            color: accent, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Body
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                business.fullName.isEmpty
                                    ? business.username
                                    : business.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            if (business.isVip) ...[
                              const SizedBox(width: 6),
                              const VipBadge(compact: true),
                            ],
                            if (business.ratingCount > 0) ...[
                              Icon(Icons.star_rounded,
                                  color: AbleColors.warning, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                business.avgRating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${business.username}',
                          style: TextStyle(color: mutedColor, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.place_outlined,
                                color: mutedColor, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                business.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (business.distanceKm != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${business.distanceKm!.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (business.accessibilityFeatures.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: business.accessibilityFeatures
                                .take(4)
                                .map((f) {
                              final icon =
                                  accessibilityCatalog[f] ?? Icons.check_rounded;
                              final label = accessibilityLabel(l10n, f);
                              return Tooltip(
                                message: label,
                                child: Semantics(
                                  label: label,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AbleTheme.iconBubble(context),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 14,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mutedColor = AbleTheme.textMuted(context);
    final titleColor = AbleTheme.textPrimary(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
        child: TtsWrapper(
          text: '${l10n.noBusinessesMatch}. ${l10n.noBusinessesMatchBody}',
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AbleTheme.iconBubble(context),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 38,
                color: AbleTheme.accent(context),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.noBusinessesMatch,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.noBusinessesMatchBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.add_business_rounded),
              label: Text(l10n.requestABusiness),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter sheet
// ---------------------------------------------------------------------------

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late BusinessSort _sort;
  late double? _maxDistance;
  late Set<String> _features;

  @override
  void initState() {
    super.initState();
    final f = ref.read(businessFiltersProvider);
    _sort = f.sort;
    _maxDistance = f.maxDistanceKm;
    _features = f.accessibilityFeatures.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final hasUserLocation =
        ref.watch(businessFiltersProvider).userLat != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF182437).withOpacity(0.96)
                  : Colors.white.withOpacity(0.96),
              border: Border(
                top: BorderSide(color: AbleTheme.glassBorder(context)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        l10n.filters,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _sort = BusinessSort.highestRated;
                            _maxDistance = null;
                            _features = {};
                          });
                        },
                        child: Text(l10n.reset),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _SectionTitle(text: l10n.sortBy),
                      ...BusinessSort.values.map((s) => RadioListTile<BusinessSort>(
                            value: s,
                            groupValue: _sort,
                            onChanged: (v) =>
                                setState(() => _sort = v ?? _sort),
                            contentPadding: EdgeInsets.zero,
                            title: Text(_sortLabel(l10n, s),
                                style: TextStyle(color: textColor)),
                            activeColor: AbleTheme.primary(context),
                            dense: true,
                          )),
                      const SizedBox(height: 16),
                      _SectionTitle(text: l10n.maximumDistance),
                      if (!hasUserLocation)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            l10n.enableLocationForDistance,
                            style:
                                TextStyle(color: mutedColor, fontSize: 12),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _maxDistance == null
                                      ? l10n.anyDistance
                                      : l10n.withinKm(
                                          _maxDistance!.toStringAsFixed(0)),
                                  style: TextStyle(color: textColor),
                                ),
                                if (_maxDistance != null)
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _maxDistance = null),
                                    child: Text(l10n.clear),
                                  ),
                              ],
                            ),
                            Slider(
                              value: _maxDistance ?? 50,
                              min: 1,
                              max: 100,
                              divisions: 99,
                              label: '${(_maxDistance ?? 50).toStringAsFixed(0)} km',
                              activeColor: AbleTheme.primary(context),
                              onChanged: (v) =>
                                  setState(() => _maxDistance = v),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: ElevatedButton(
                      onPressed: () {
                        final notifier =
                            ref.read(businessFiltersProvider.notifier);
                        notifier.setSort(_sort);
                        notifier.setMaxDistance(_maxDistance);
                        notifier.setAccessibility(_features.toList());
                        Navigator.pop(context);
                      },
                      child: Text(l10n.applyFilters),
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AbleTheme.textPrimary(context),
          fontSize: 14,
        ),
      ),
    );
  }
}