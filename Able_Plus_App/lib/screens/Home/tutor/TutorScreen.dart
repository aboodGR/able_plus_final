import 'dart:math' as math;
import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/tutors_provider.dart';
import 'package:ableplusproject/providers/vip_provider.dart';
import 'package:ableplusproject/screens/Messages/chat_screen.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:ableplusproject/widgets/VipBadge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  dynamic _rawSubject(Map<String, dynamic> tutor) {
    return tutor['subject'] ??
        tutor['subjects'] ??
        tutor['subject_text'] ??
        tutor['subjectText'];
  }

  String _subjectText(dynamic raw) {
    if (raw == null) return '';

    if (raw is Iterable) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
          .join(', ');
    }

    var text = raw.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text == '[]' ||
        text == '{}') {
      return '';
    }

    final looksLikeWrappedList =
        (text.startsWith('{') && text.endsWith('}')) ||
        (text.startsWith('[') && text.endsWith(']'));

    if (looksLikeWrappedList) {
      text = text.substring(1, text.length - 1).trim();

      if (text.isEmpty) return '';

      return text
          .split(',')
          .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
          .join(', ');
    }

    return text;
  }

  String _readText(Map<String, dynamic> tutor, List<String> keys) {
    for (final key in keys) {
      final value = tutor[key];

      if (value == null) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return '';
  }

  String _tutorId(Map<String, dynamic> tutor) {
    return _readText(tutor, ['id', 'auth_user_id']);
  }

  bool _dbVipFlag(Map<String, dynamic> tutor) {
    final value = tutor['is_vip'] ?? tutor['isVip'] ?? tutor['vip'];

    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'yes';
  }

  List<Map<String, dynamic>> _applyVipStatus({
    required List<Map<String, dynamic>> tutors,
    required Map<String, dynamic>? vipMap,
  }) {
    return tutors.map((tutor) {
      final map = Map<String, dynamic>.from(tutor);
      final id = _tutorId(map);

      final fromVipProvider =
          id.isNotEmpty && vipMap != null && vipMap[vipKey('tutor', id)] != null;

      map['is_vip'] = fromVipProvider || _dbVipFlag(map);

      return map;
    }).toList();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> tutors) {
    if (_query.isEmpty) return tutors;

    return tutors.where((tutor) {
      final username = _readText(tutor, ['username']).toLowerCase();
      final fullName = _readText(
        tutor,
        ['full_name', 'fullName'],
      ).toLowerCase();
      final email = _readText(tutor, ['email']).toLowerCase();
      final bio = _readText(tutor, ['bio']).toLowerCase();
      final subject = _subjectText(_rawSubject(tutor)).toLowerCase();

      final location = _governorateSearchText(
        tutor['latitude'],
        tutor['longitude'],
      ).toLowerCase();

      return username.contains(_query) ||
          fullName.contains(_query) ||
          email.contains(_query) ||
          bio.contains(_query) ||
          location.contains(_query) ||
          subject.contains(_query);
    }).toList();
  }

  Future<void> _refreshTutors() async {
    ref.invalidate(tutorsProvider);
    ref.invalidate(activeVipProvidersProvider);

    await Future.wait([
      ref.read(tutorsProvider.future),
      ref.read(activeVipProvidersProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);

    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;
    final accentColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    final tutorsAsync = ref.watch(tutorsProvider);
    final vipAsync = ref.watch(activeVipProvidersProvider);

    return AbleScaffold(
      title: l10n.tutors,

      // مهم: صفحة Tutors ليست Home.
      // 0 = Home, 1 = Tutors/Location حسب ترتيب الـ Bottom Nav عندك.
      // هذا يحل مشكلة أن زر Home تحت لا يعمل.
      currentIndex: 1,

      showBackButton: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TtsWrapper(
              text: l10n.searchTutors,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.80),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.white.withOpacity(0.70),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: titleColor),
                  decoration: InputDecoration(
                    hintText: l10n.searchTutors,
                    hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: mutedColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: tutorsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${l10n.error}: $error',
                    style: const TextStyle(color: AbleColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (rawTutors) {
                final vipMap = vipAsync.valueOrNull;
                final tutors = _applyVipStatus(
                  tutors: rawTutors,
                  vipMap: vipMap,
                );

                final filtered = _filter(tutors);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          TtsWrapper(
                            text: l10n.tutorsAvailable(filtered.length),
                            child: Text(
                              l10n.tutorsAvailable(filtered.length),
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: TtsWrapper(
                                text: l10n.noTutorsFound,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 64,
                                      color: mutedColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.noTutorsFound,
                                      style: TextStyle(
                                        color: mutedColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshTutors,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  100,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final tutor = filtered[index];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _TutorCard(
                                      tutor: tutor,
                                      subjectText:
                                          _subjectText(_rawSubject(tutor)),
                                      accentColor: accentColor,
                                      titleColor: titleColor,
                                      mutedColor: mutedColor,
                                      isDark: isDark,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorCard extends ConsumerWidget {
  const _TutorCard({
    required this.tutor,
    required this.subjectText,
    required this.accentColor,
    required this.titleColor,
    required this.mutedColor,
    required this.isDark,
  });

  final Map<String, dynamic> tutor;
  final String subjectText;
  final Color accentColor;
  final Color titleColor;
  final Color mutedColor;
  final bool isDark;

  String _readText(List<String> keys) {
    for (final key in keys) {
      final value = tutor[key];

      if (value == null) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return '';
  }

  double _readRating() {
    final value =
        tutor['rating'] ?? tutor['avg_rating'] ?? tutor['average_rating'];

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _readVip() {
    final value = tutor['is_vip'] ?? tutor['isVip'] ?? tutor['vip'];

    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'yes';
  }

  String _avatarLetter(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) return 'T';

    return trimmed.substring(0, 1).toUpperCase();
  }

  String _displayName() {
    final username = _readText(['username']);
    final fullName = _readText(['full_name', 'fullName']);

    if (username.isNotEmpty) return username;
    if (fullName.isNotEmpty) return fullName;

    return 'Tutor';
  }

  String _fullName() {
    return _readText(['full_name', 'fullName']);
  }

  String _tutorId() {
    return _readText(['id', 'auth_user_id']);
  }

  void _openProfile(BuildContext context) {
    final id = _tutorId();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor ID is missing')),
      );
      return;
    }

    context.push('/profile/tutor/$id');
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final supabase = Supabase.instance.client;

    final viewer = await ref.read(viewerProvider.future);

    if (!context.mounted) return;

    if (viewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseLoginFirst)),
      );
      return;
    }

    if (viewer.role != 'client') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onlyClientsCanMessageTutors)),
      );
      return;
    }

    final tutorId = _tutorId();

    if (tutorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: Tutor ID is missing')),
      );
      return;
    }

    try {
      final conversationId = await supabase.rpc(
        'get_or_create_conversation',
        params: {
          'p_my_id': viewer.id,
          'p_my_type': viewer.role,
          'p_other_id': tutorId,
          'p_other_type': 'tutor',
        },
      );

      if (!context.mounted) return;

      final fullName = _fullName();
      final displayName = fullName.isNotEmpty ? fullName : _displayName();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId.toString(),
            otherName: displayName,
            otherImage: _readText([
              'image_url',
              'avatar_url',
              'profile_image_url',
            ]),
            otherId: tutorId,
            otherType: 'tutor',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatError(error.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final id = _tutorId();
    final usernameOrName = _displayName();
    final fullName = _fullName();
    final bio = _readText(['bio']);

    final location = _governorateFromCoordinates(
      lat: _toDouble(tutor['latitude']),
      lng: _toDouble(tutor['longitude']),
      isArabic: l10n.localeName == 'ar',
    );

    final image = _readText([
      'image_url',
      'avatar_url',
      'profile_image_url',
    ]);

    final displaySubject =
        subjectText.trim().isEmpty ? l10n.unknownSubject : subjectText.trim();

    final rating = _readRating();
    final isVip = _readVip();

    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.80);

    final cardBorder = isDark
        ? Colors.white.withOpacity(0.09)
        : Colors.white.withOpacity(0.65);

    final isAr = l10n.localeName == 'ar';
    final ratingLabel = isAr ? 'التقييم $rating' : 'Rating $rating';

    final spokenParts = <String>[
      usernameOrName,
      if (fullName.isNotEmpty && fullName != usernameOrName) fullName,
      displaySubject,
      if (location.isNotEmpty) location,
      ratingLabel,
      if (bio.isNotEmpty) bio,
      if (isVip) 'VIP',
    ];

    final spokenText =
        spokenParts.where((part) => part.trim().isNotEmpty).join('. ');

    return VipGoldFrame(
      isVip: isVip,
      child: TtsWrapper(
        text: spokenText,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: id.isEmpty ? null : () => _openProfile(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.20 : 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage:
                              image.isNotEmpty ? NetworkImage(image) : null,
                          backgroundColor: accentColor.withOpacity(0.15),
                          child: image.isEmpty
                              ? Text(
                                  _avatarLetter(usernameOrName),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      usernameOrName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                  if (isVip) ...[
                                    const SizedBox(width: 6),
                                    const VipBadge(compact: true),
                                  ],
                                ],
                              ),
                              if (fullName.isNotEmpty &&
                                  fullName != usernameOrName) ...[
                                const SizedBox(height: 4),
                                Text(
                                  fullName,
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    color: accentColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      displaySubject,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: mutedColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: titleColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'profile') {
                              _openProfile(context);
                            }

                            if (value == 'chat') {
                              _openChat(context, ref);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'profile',
                              enabled: id.isNotEmpty,
                              child: Text(l10n.openProfile),
                            ),
                            PopupMenuItem(
                              value: 'chat',
                              child: Text(l10n.startChat),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          bio,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mutedColor,
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                id.isEmpty ? null : () => _openProfile(context),
                            icon: const Icon(Icons.person),
                            label: Text(l10n.profileButton),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openChat(context, ref),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(l10n.chatButton),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              foregroundColor: accentColor,
                              side: BorderSide(color: accentColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
    );
  }
}

class _JordanGovernorate {
  const _JordanGovernorate({
    required this.en,
    required this.ar,
    required this.lat,
    required this.lng,
  });

  final String en;
  final String ar;
  final double lat;
  final double lng;
}

const List<_JordanGovernorate> _jordanGovernorates = [
  _JordanGovernorate(en: 'Amman', ar: 'عمان', lat: 31.9539, lng: 35.9106),
  _JordanGovernorate(en: 'Zarqa', ar: 'الزرقاء', lat: 32.0608, lng: 36.0942),
  _JordanGovernorate(en: 'Irbid', ar: 'إربد', lat: 32.5556, lng: 35.8500),
  _JordanGovernorate(en: 'Balqa', ar: 'البلقاء', lat: 32.0392, lng: 35.7272),
  _JordanGovernorate(en: 'Madaba', ar: 'مادبا', lat: 31.7167, lng: 35.8000),
  _JordanGovernorate(en: 'Jerash', ar: 'جرش', lat: 32.2747, lng: 35.8961),
  _JordanGovernorate(en: 'Ajloun', ar: 'عجلون', lat: 32.3333, lng: 35.7517),
  _JordanGovernorate(en: 'Mafraq', ar: 'المفرق', lat: 32.3429, lng: 36.2080),
  _JordanGovernorate(en: 'Karak', ar: 'الكرك', lat: 31.1853, lng: 35.7047),
  _JordanGovernorate(
    en: 'Tafilah',
    ar: 'الطفيلة',
    lat: 30.8333,
    lng: 35.6000,
  ),
  _JordanGovernorate(en: 'Ma’an', ar: 'معان', lat: 30.1962, lng: 35.7341),
  _JordanGovernorate(en: 'Aqaba', ar: 'العقبة', lat: 29.5319, lng: 35.0061),
];

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString());
}

String _governorateSearchText(dynamic latValue, dynamic lngValue) {
  final lat = _toDouble(latValue);
  final lng = _toDouble(lngValue);

  if (lat == null || lng == null) return '';

  final en = _governorateFromCoordinates(
    lat: lat,
    lng: lng,
    isArabic: false,
  );

  final ar = _governorateFromCoordinates(
    lat: lat,
    lng: lng,
    isArabic: true,
  );

  return '$en $ar';
}

String _governorateFromCoordinates({
  required double? lat,
  required double? lng,
  required bool isArabic,
}) {
  if (lat == null || lng == null) return '';

  _JordanGovernorate nearest = _jordanGovernorates.first;
  double bestDistance = double.infinity;

  for (final governorate in _jordanGovernorates) {
    final distance = _distanceKm(
      lat,
      lng,
      governorate.lat,
      governorate.lng,
    );

    if (distance < bestDistance) {
      bestDistance = distance;
      nearest = governorate;
    }
  }

  return isArabic ? nearest.ar : nearest.en;
}

double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371.0;

  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadius * c;
}

double _degToRad(double degree) {
  return degree * math.pi / 180;
}
