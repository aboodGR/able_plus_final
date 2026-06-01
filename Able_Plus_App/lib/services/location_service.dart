import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Result of a location capture attempt.
///
/// [address] is null when reverse-geocoding fails — the caller should treat
/// that as "we have coordinates but no human-readable address" and either
/// store NULL or prompt the user to fill it in later. We intentionally do
/// NOT fall back to a "lat, long" string here: that string would otherwise
/// leak into the `location` column and be displayed as the place's address.
class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// Reusable location service used by all signup flows.
/// Handles permission, capture, and reverse-geocoding to a readable address.
class LocationService {
  /// Shows a friendly pre-permission dialog, then requests OS permission,
  /// captures the user's current position, and reverse-geocodes it.
  ///
  /// [showPublicNotice] controls the dialog wording:
  ///   - true  → "Your location is shown on the map so users can find you."
  ///             (businesses & charities)
  ///   - false → "Your location is used only to show you nearby places.
  ///             It is never shared with other users."
  ///             (tutors & clients)
  ///
  /// Returns a [LocationResult] on success, or null if the user declined
  /// or something went wrong. The returned result's `address` may itself
  /// be null if reverse-geocoding failed — coordinates are still valid.
  static Future<LocationResult?> requestAndGetLocation(
    BuildContext context, {
    required bool showPublicNotice,
  }) async {
    // Step 1: show the pre-permission explanation dialog
    final agreed = await _showPrePermissionDialog(
      context,
      showPublicNotice: showPublicNotice,
    );
    if (agreed != true) return null;

    // Step 2: make sure location services are turned on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError(context, 'Please turn on location services and try again.');
      return null;
    }

    // Step 3: request OS-level permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showError(context, 'Location permission is required to continue.');
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      _showError(
        context,
        'Location permission was permanently denied. Please enable it from your device settings.',
      );
      return null;
    }

    // Step 4: get the current position
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      _showError(context, 'Could not get your location: $e');
      return null;
    }

    // Step 5: reverse-geocode to a readable address (best-effort).
    // If this fails for any reason, `address` stays null — we do NOT
    // fall back to a "lat, long" string, which would leak into the
    // `location` column and be displayed to users as the place's address.
    String? address;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Build the most useful readable address we can.
        final parts = <String>[
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
          if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
          if ((p.country ?? '').isNotEmpty) p.country!,
        ];

        // Deduplicate while preserving order.
        final seen = <String>{};
        final unique = parts.where((s) => seen.add(s)).toList();

        if (unique.isNotEmpty) {
          address = unique.join(', ');
        }
      }
    } catch (_) {
      // Reverse-geocoding can fail (e.g. no network, plugin unsupported
      // on this platform, geocoder rate limit). Leave `address` as null.
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  static Future<bool?> _showPrePermissionDialog(
    BuildContext context, {
    required bool showPublicNotice,
  }) {
    final message = showPublicNotice
        ? 'ABLE+ uses your location to show your place on the map so users can find you.'
        : 'ABLE+ uses your location to show you nearby accessible places. '
            'Your location is never shared with other users.';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const Icon(Icons.location_on_outlined, size: 36),
          title: const Text(
            'Allow location?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.45),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}