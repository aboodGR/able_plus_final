import 'package:flutter/material.dart';

import 'package:ableplusproject/l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// A button-style field that replaces the "location" text input.
/// Tapping it captures the user's current location and shows the
/// reverse-geocoded address as the button label.
///
/// Use [showPublicNotice]:
///   - true for businesses & charities (location is public on map)
///   - false for tutors & clients (location is private)
class LocationPickerButton extends StatefulWidget {
  const LocationPickerButton({
    super.key,
    required this.onLocationPicked,
    required this.showPublicNotice,
    this.hint,
  });

  /// Called when a location is successfully picked.
  final void Function(LocationResult result) onLocationPicked;

  /// See [LocationService.requestAndGetLocation].
  final bool showPublicNotice;

  /// Text shown when no location has been picked yet.
  /// When null, falls back to the localized "Use current location".
  final String? hint;

  @override
  State<LocationPickerButton> createState() => _LocationPickerButtonState();
}

class _LocationPickerButtonState extends State<LocationPickerButton> {
  LocationResult? _picked;
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);

    final result = await LocationService.requestAndGetLocation(
      context,
      showPublicNotice: widget.showPublicNotice,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _picked = result);
      widget.onLocationPicked(result);
    }

    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mutedColor = isDark
        ? AbleColors.darkTextMuted
        : AbleColors.lightTextMuted;
    final textColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final accentColor = isDark
        ? AbleColors.darkSecondary
        : AbleColors.lightPrimaryDark;

    final hasValue = _picked != null;
    final hasAddress =
        hasValue && _picked!.address != null && _picked!.address!.isNotEmpty;

    // What we show as the subtitle:
    //   - no pick yet  → the hint
    //   - picked + addr → the resolved address
    //   - picked but no address → friendly note (do NOT show lat/long)
    final String subtitle;
    if (!hasValue) {
      subtitle = l10n.tapToDetectGps;
    } else if (hasAddress) {
      subtitle = _picked!.address!;
    } else {
      subtitle = l10n.locationSavedNote;
    }

    final String title =
        hasValue ? l10n.currentLocation : (widget.hint ?? l10n.useCurrentLocation);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF3F8FC).withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFD9E8F3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.my_location_rounded, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                Transform.flip(
                  flipX: !hasValue &&
                      Directionality.of(context) == TextDirection.rtl,
                  child: Icon(
                    hasValue
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: hasValue ? Colors.green : accentColor,
                    size: 28,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}