class CharityModel {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String charityName;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? profileImage;
  final bool isVip;
  final DateTime? vipExpiresAt;

  /// Distance from the current user in km. Filled in client-side after
  /// the user grants location permission. `null` when unknown.
  final double? distanceKm;

  const CharityModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.charityName,
    required this.location,
    this.latitude,
    this.longitude,
    this.profileImage,
    this.isVip = false,
    this.vipExpiresAt,
    this.distanceKm,
  });

  String get displayName =>
      charityName.isNotEmpty ? charityName : (fullName.isNotEmpty ? fullName : username);
}