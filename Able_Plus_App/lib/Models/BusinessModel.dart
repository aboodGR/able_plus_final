class BusinessModel {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? category;
  final String? description;
  final List<String> accessibilityFeatures;
  final String? profileImage;
  final double avgRating;
  final int ratingCount;
  final bool isVip;
  final DateTime? vipExpiresAt;

  /// Distance from the current user in km. Filled in client-side after
  /// the user grants location permission. `null` when unknown.
  final double? distanceKm;

  const BusinessModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.location,
    this.latitude,
    this.longitude,
    this.category,
    this.description,
    this.accessibilityFeatures = const [],
    this.profileImage,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.isVip = false,
    this.vipExpiresAt,
    this.distanceKm,
  });

  BusinessModel copyWith({double? distanceKm}) => BusinessModel(
        id: id,
        username: username,
        fullName: fullName,
        email: email,
        location: location,
        latitude: latitude,
        longitude: longitude,
        category: category,
        description: description,
        accessibilityFeatures: accessibilityFeatures,
        profileImage: profileImage,
        avgRating: avgRating,
        ratingCount: ratingCount,
        isVip: isVip,
        vipExpiresAt: vipExpiresAt,
        distanceKm: distanceKm ?? this.distanceKm,
      );
}