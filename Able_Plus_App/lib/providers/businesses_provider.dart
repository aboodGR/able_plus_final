import 'dart:math';

import 'package:ableplusproject/Models/BusinessModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vip_provider.dart';

/// Sort modes available on the businesses page.
enum BusinessSort {
  highestRated,
  mostReviewed,
  closest,
  alphabetical,
}

/// Holds the current filter / search / sort state for the businesses page.
class BusinessFilters {
  final String query;
  final String? category;
  final BusinessSort sort;
  final double? maxDistanceKm; // null = no distance filter
  final List<String> accessibilityFeatures; // must include ALL
  final double? userLat;
  final double? userLng;

  const BusinessFilters({
    this.query = '',
    this.category,
    this.sort = BusinessSort.highestRated,
    this.maxDistanceKm,
    this.accessibilityFeatures = const [],
    this.userLat,
    this.userLng,
  });

  BusinessFilters copyWith({
    String? query,
    Object? category = _sentinel,
    BusinessSort? sort,
    Object? maxDistanceKm = _sentinel,
    List<String>? accessibilityFeatures,
    Object? userLat = _sentinel,
    Object? userLng = _sentinel,
  }) {
    return BusinessFilters(
      query: query ?? this.query,
      category: category == _sentinel ? this.category : category as String?,
      sort: sort ?? this.sort,
      maxDistanceKm: maxDistanceKm == _sentinel
          ? this.maxDistanceKm
          : maxDistanceKm as double?,
      accessibilityFeatures:
          accessibilityFeatures ?? this.accessibilityFeatures,
      userLat: userLat == _sentinel ? this.userLat : userLat as double?,
      userLng: userLng == _sentinel ? this.userLng : userLng as double?,
    );
  }
}

const _sentinel = Object();

class BusinessFiltersNotifier extends StateNotifier<BusinessFilters> {
  BusinessFiltersNotifier() : super(const BusinessFilters());

  void setQuery(String value) => state = state.copyWith(query: value);
  void setCategory(String? value) => state = state.copyWith(category: value);
  void setSort(BusinessSort value) => state = state.copyWith(sort: value);
  void setMaxDistance(double? value) =>
      state = state.copyWith(maxDistanceKm: value);
  void setAccessibility(List<String> features) =>
      state = state.copyWith(accessibilityFeatures: features);
  void setUserLocation(double? lat, double? lng) =>
      state = state.copyWith(userLat: lat, userLng: lng);

  void clearAll() => state = BusinessFilters(
        userLat: state.userLat,
        userLng: state.userLng,
      );
}

final businessFiltersProvider =
    StateNotifierProvider<BusinessFiltersNotifier, BusinessFilters>(
  (ref) => BusinessFiltersNotifier(),
);

/// Returns the list of businesses respecting the current filters.
final businessesProvider =
    FutureProvider.autoDispose<List<BusinessModel>>((ref) async {
  final filters = ref.watch(businessFiltersProvider);
  final supabase = Supabase.instance.client;
  final activeVip = await ref.watch(activeVipProvidersProvider.future);

  final rows = await supabase.from('businesses').select();

  // Fetch all rating summaries in one query and index by business_id.
  final ratingRows = await supabase.from('business_rating_summary').select();
  final ratingMap = <String, Map<String, dynamic>>{
    for (final r in ratingRows) r['business_id'].toString(): r,
  };

  // Fetch all profiles for businesses in one query.
  final profileRows = await supabase
      .from('profiles')
      .select('business_id, profile_pic_url')
      .not('business_id', 'is', null);
  final profileMap = <String, String?>{
    for (final p in profileRows)
      p['business_id'].toString(): p['profile_pic_url']?.toString(),
  };

  final businesses = <BusinessModel>[];

  for (final row in rows) {
    final id = row['id'].toString();
    final rating = ratingMap[id];
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();

    double? distanceKm;
    if (filters.userLat != null &&
        filters.userLng != null &&
        lat != null &&
        lng != null) {
      distanceKm = _haversineKm(filters.userLat!, filters.userLng!, lat, lng);
    }

    businesses.add(
      BusinessModel(
        id: id,
        username: row['username']?.toString() ?? '',
        fullName: row['full_name']?.toString() ?? '',
        email: row['email']?.toString() ?? '',
        location: row['location']?.toString() ?? '',
        latitude: lat,
        longitude: lng,
        category: row['category']?.toString(),
        description: row['description']?.toString(),
        accessibilityFeatures: _parseFeatures(row['accessibility_features']),
        profileImage: profileMap[id],
        avgRating: (rating?['avg_rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (rating?['rating_count'] as num?)?.toInt() ?? 0,
        distanceKm: distanceKm,
        isVip: activeVip.containsKey(vipKey('business', id)),
        vipExpiresAt: activeVip[vipKey('business', id)]?.expiresAt.toLocal(),
      ),
    );
  }

  // Apply filters client-side.
  Iterable<BusinessModel> filtered = businesses;

  if (filters.query.trim().isNotEmpty) {
    final q = filters.query.trim().toLowerCase();
    filtered = filtered.where((b) =>
        b.username.toLowerCase().contains(q) ||
        b.fullName.toLowerCase().contains(q));
  }

  if (filters.category != null) {
    filtered = filtered.where((b) => b.category == filters.category);
  }

  if (filters.maxDistanceKm != null) {
    filtered = filtered.where(
        (b) => b.distanceKm != null && b.distanceKm! <= filters.maxDistanceKm!);
  }

  if (filters.accessibilityFeatures.isNotEmpty) {
    filtered = filtered.where((b) => filters.accessibilityFeatures
        .every((f) => b.accessibilityFeatures.contains(f)));
  }

  final list = filtered.toList();

  switch (filters.sort) {
    case BusinessSort.highestRated:
      list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      break;
    case BusinessSort.mostReviewed:
      list.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
      break;
    case BusinessSort.closest:
      list.sort((a, b) {
        final ad = a.distanceKm ?? double.infinity;
        final bd = b.distanceKm ?? double.infinity;
        return ad.compareTo(bd);
      });
      break;
    case BusinessSort.alphabetical:
      list.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      break;
  }

  list.sort((a, b) {
    if (a.isVip != b.isVip) return a.isVip ? -1 : 1;
    return 0;
  });

  return list;
});

/// Distinct categories in the database, used to render category chips.
final businessCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final supabase = Supabase.instance.client;
  final rows = await supabase
      .from('businesses')
      .select('category')
      .not('category', 'is', null);

  final set = <String>{};
  for (final r in rows) {
    final c = r['category']?.toString();
    if (c != null && c.isNotEmpty) set.add(c);
  }
  final list = set.toList()..sort();
  return list;
});

List<String> _parseFeatures(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) {
    return raw.map((e) => e.toString()).toList();
  }
  return const [];
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthKm = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) *
          cos(_deg2rad(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthKm * c;
}

double _deg2rad(double deg) => deg * (pi / 180);

/// All tutors, sorted by rating. One query, cached.
/// 
final tutorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final activeVip = await ref.watch(activeVipProvidersProvider.future);
  final rows = await supabase
      .from('tutors')
      .select('id, username, full_name, email, bio, '
          'subject, rating, image_url')
      .order('rating', ascending: false);
  final tutors = List<Map<String, dynamic>>.from(rows).map((raw) {
    final row = Map<String, dynamic>.from(raw);
    final status = activeVip[vipKey('tutor', row['id'].toString())];
    row['is_vip'] = status != null;
    row['vip_expires_at'] = status?.expiresAt.toIso8601String();
    return row;
  }).toList();
  tutors.sort((a, b) {
    final av = a['is_vip'] == true;
    final bv = b['is_vip'] == true;
    if (av != bv) return av ? -1 : 1;
    return ((b['rating'] as num?)?.toDouble() ?? 0)
        .compareTo((a['rating'] as num?)?.toDouble() ?? 0);
  });
  return tutors;
});