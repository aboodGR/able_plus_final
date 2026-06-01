import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vip_provider.dart';

class PlaceModel {
  final String id;
  final String name;
  final String address;
  final double rating;
  final List<String> accessibilityFeatures;
  final double latitude;
  final double longitude;
  final String kind; // 'business' or 'charity'
  final bool isVip;
  final DateTime? vipExpiresAt;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.accessibilityFeatures,
    required this.latitude,
    required this.longitude,
    required this.kind,
    this.isVip = false,
    this.vipExpiresAt,
  });
}

List<String> _parseFeatures(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) {
    return raw.map((e) => e.toString()).toList();
  }
  return const [];
}

final placesProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final activeVip = await ref.watch(activeVipProvidersProvider.future);

  // 1) Businesses (with their real lat/long + accessibility_features)
  final businesses = await supabase
      .from('businesses')
      .select(
        'id, full_name, username, location, latitude, longitude, '
        'accessibility_features',
      );

  final places = <PlaceModel>[];
  final ratingRows = await supabase.from('business_rating_summary').select('business_id, avg_rating');
  final ratingMap = <String, double>{
    for (final r in ratingRows) r['business_id'].toString(): (r['avg_rating'] as num?)?.toDouble() ?? 0,
  };

  for (final business in businesses) {
    final lat = business['latitude'];
    final lng = business['longitude'];
    if (lat == null || lng == null) continue; // skip older rows w/ no GPS

    final businessId = business['id'].toString();

    final averageRating = ratingMap[businessId] ?? 0;

    places.add(
      PlaceModel(
        id: businessId,
        name: business['full_name']?.toString() ??
            business['username']?.toString() ??
            'Business',
        address: business['location']?.toString() ?? 'No location',
        rating: averageRating,
        accessibilityFeatures: _parseFeatures(
          business['accessibility_features'],
        ),
        latitude: (lat as num).toDouble(),
        longitude: (lng as num).toDouble(),
        kind: 'business',
        isVip: activeVip.containsKey(vipKey('business', businessId)),
        vipExpiresAt: activeVip[vipKey('business', businessId)]?.expiresAt.toLocal(),
      ),
    );
  }

  // 2) Charities (no ratings yet, no accessibility_features column on this table)
  final charities = await supabase
      .from('charities')
      .select('id, full_name, username, charity_name, location, latitude, longitude');

  for (final charity in charities) {
    final lat = charity['latitude'];
    final lng = charity['longitude'];
    if (lat == null || lng == null) continue;

    places.add(
      PlaceModel(
        id: charity['id'].toString(),
        name: charity['charity_name']?.toString() ??
            charity['full_name']?.toString() ??
            'Charity',
        address: charity['location']?.toString() ?? 'No location',
        rating: 0,
        accessibilityFeatures: const [],
        latitude: (lat as num).toDouble(),
        longitude: (lng as num).toDouble(),
        kind: 'charity',
        isVip: activeVip.containsKey(vipKey('charity', charity['id'].toString())),
        vipExpiresAt: activeVip[vipKey('charity', charity['id'].toString())]?.expiresAt.toLocal(),
      ),
    );
  }

  places.sort((a, b) {
    if (a.isVip != b.isVip) return a.isVip ? -1 : 1;
    return b.rating.compareTo(a.rating);
  });
  return places;
});