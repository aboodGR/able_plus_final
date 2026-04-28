
import 'dart:ui';

import 'package:ableplusproject/theme/App_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.role,
    this.userId,
    this.currentUserProfile = false,
  });

  final String? role;
  final String? userId;
  final bool currentUserProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  _ViewerInfo? viewer;
  _ProfileData? profile;
  bool isFollowing = false;
  double? myRating;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      viewer = await _loadViewerInfo();

      if (widget.currentUserProfile) {
        if (viewer == null) {
          throw Exception('No user is logged in.');
        }
        profile = await _loadProfileByRoleAndId(viewer!.role, viewer!.id);
      } else {
        final role = widget.role;
        final userId = widget.userId;
        if (role == null || userId == null) {
          throw Exception('Missing profile route information.');
        }
        profile = await _loadProfileByRoleAndId(role, userId);
      }

      if (profile == null) {
        throw Exception('Profile not found.');
      }

      await _loadVisitorActions();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<_ViewerInfo?> _loadViewerInfo() async {
    final user = supabase.auth.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) return null;

    final searches = [
      ('client', 'clients'),
      ('tutor', 'tutors'),
      ('business', 'businesses'),
      ('charity', 'charities'),
    ];

    for (final item in searches) {
      final row = await supabase
          .from(item.$2)
          .select('id, full_name, username, email')
          .eq('email', email)
          .maybeSingle();

      if (row != null) {
        return _ViewerInfo(
          role: item.$1,
          id: row['id'].toString(),
          email: row['email']?.toString() ?? email,
        );
      }
    }

    return null;
  }

  Future<_ProfileData?> _loadProfileByRoleAndId(String role, String id) async {
    final accountTable = _tableForRole(role);
    final profileColumn = _profileColumnForRole(role);

    final account = await supabase
        .from(accountTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (account == null) return null;

    final profileRow = await supabase
        .from('profiles')
        .select()
        .eq(profileColumn, id)
        .maybeSingle();

    return _ProfileData(
      role: role,
      id: id,
      fullName: account['full_name']?.toString() ?? 'Able+ User',
      username: account['username']?.toString() ?? 'username',
      email: account['email']?.toString() ?? '',
      location: account['location']?.toString(),
      charityName: account['charity_name']?.toString(),
      profileId: profileRow?['id']?.toString(),
      description: profileRow?['description']?.toString() ?? '',
      profilePicUrl: profileRow?['profile_pic_url']?.toString(),
      followersCount: _asInt(profileRow?['followers_count']),
      postsCount: _asInt(profileRow?['posts_count']),
      averageRating: _asDouble(profileRow?['average_rating']),
    );
  }

  Future<void> _loadVisitorActions() async {
    final p = profile;
    final v = viewer;
    if (p == null || v == null) return;

    if (!isOwnProfile && v.role == 'client') {
      final followQuery = supabase
          .from('follows')
          .select('id')
          .eq('follower_client_id', v.id);

      final followRow = await _applyFollowedFilter(followQuery, p).maybeSingle();
      isFollowing = followRow != null;

      if (p.role == 'tutor') {
        final row = await supabase
            .from('tutor_ratings')
            .select('rating')
            .eq('client_id', v.id)
            .eq('tutor_id', p.id)
            .maybeSingle();
        myRating = _asDouble(row?['rating']);
      } else if (p.role == 'business') {
        final row = await supabase
            .from('business_ratings')
            .select('rating')
            .eq('client_id', v.id)
            .eq('business_id', p.id)
            .maybeSingle();
        myRating = _asDouble(row?['rating']);
      } else if (p.role == 'charity') {
        final row = await supabase
            .from('charity_ratings')
            .select('rating')
            .eq('client_id', v.id)
            .eq('charity_id', p.id)
            .maybeSingle();
        myRating = _asDouble(row?['rating']);
      }
    }
  }

  dynamic _applyFollowedFilter(dynamic query, _ProfileData p) {
    switch (p.role) {
      case 'client':
        return query.eq('followed_client_id', p.id);
      case 'tutor':
        return query.eq('followed_tutor_id', p.id);
      case 'business':
        return query.eq('followed_business_id', p.id);
      case 'charity':
        return query.eq('followed_charity_id', p.id);
      default:
        return query;
    }
  }

  bool get isOwnProfile {
    final p = profile;
    final v = viewer;
    if (p == null || v == null) return false;
    return p.role == v.role && p.id == v.id;
  }

  bool get canVisitorRate {
  final p = profile;
  final v = viewer;
  if (p == null || v == null) return false;

  if (p.role == 'client') return false;

  return !isOwnProfile && v.role == 'client';
}

  Future<void> pickProfileImage() async {
    final p = profile;
    if (p == null || !isOwnProfile) return;

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
  final picked = await picker.pickImage(
    source: source,
    imageQuality: 85,
  );

  if (picked == null) return;

  final bytes = await picked.readAsBytes();

  final path =
      '${p.role}/${p.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

  await supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

  final url = supabase.storage.from('avatars').getPublicUrl(path);

  await _ensureProfileRowExists(p);

  await supabase
      .from('profiles')
      .update({'profile_pic_url': url})
      .eq(_profileColumnForRole(p.role), p.id);

  if (!mounted) return;

  setState(() {
    profile = p.copyWith(profilePicUrl: url);
  });

  _snack('Profile photo updated.');
} catch (e) {
  _snack('Upload failed: $e');
}
  }

  Future<void> editProfile() async {
    final p = profile;
    if (p == null || !isOwnProfile) return;

    final nameController = TextEditingController(text: p.fullName);
    final usernameController = TextEditingController(text: p.username);
    final descriptionController = TextEditingController(text: p.description);
    final locationController = TextEditingController(text: p.location ?? '');
    final charityNameController = TextEditingController(text: p.charityName ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 10),
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
              ),
              if (p.role == 'business' || p.role == 'charity') ...[
                const SizedBox(height: 10),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              ],
              if (p.role == 'charity') ...[
                const SizedBox(height: 10),
                TextField(controller: charityNameController, decoration: const InputDecoration(labelText: 'Charity name')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _saveProfileEdit(
                fullName: nameController.text.trim(),
                username: usernameController.text.trim(),
                description: descriptionController.text.trim(),
                location: locationController.text.trim(),
                charityName: charityNameController.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileEdit({
    required String fullName,
    required String username,
    required String description,
    required String location,
    required String charityName,
  }) async {
    final p = profile;
    if (p == null) return;

    if (fullName.isEmpty || username.isEmpty) {
      _snack('Full name and username are required.');
      return;
    }

    setState(() => isSaving = true);
    try {
      final accountUpdate = <String, dynamic>{
        'full_name': fullName,
        'username': username,
      };

      if (p.role == 'business') {
        if (location.isEmpty) throw Exception('Location is required for business profiles.');
        accountUpdate['location'] = location;
      }

      if (p.role == 'charity') {
        if (location.isEmpty || charityName.isEmpty) {
          throw Exception('Charity name and location are required for charity profiles.');
        }
        accountUpdate['location'] = location;
        accountUpdate['charity_name'] = charityName;
      }

      await supabase.from(_tableForRole(p.role)).update(accountUpdate).eq('id', p.id);

      await _ensureProfileRowExists(p);
      await supabase
          .from('profiles')
          .update({'description': description})
          .eq(_profileColumnForRole(p.role), p.id);

      await loadProfile();
      _snack('Profile updated.');
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _ensureProfileRowExists(_ProfileData p) async {
    final column = _profileColumnForRole(p.role);
    final existing = await supabase.from('profiles').select('id').eq(column, p.id).maybeSingle();
    if (existing != null) return;
    await supabase.from('profiles').insert({column: p.id});
  }

  Future<void> toggleFollow() async {
    final p = profile;
    final v = viewer;
    if (p == null || v == null || v.role != 'client' || isOwnProfile) return;

    try {
      if (isFollowing) {
        final deleteQuery = supabase.from('follows').delete().eq('follower_client_id', v.id);
        await _applyFollowedFilter(deleteQuery, p);
      } else {
        final row = <String, dynamic>{'follower_client_id': v.id};
        row[_followedColumnForRole(p.role)] = p.id;
        await supabase.from('follows').insert(row);
      }
      await loadProfile();
    } catch (e) {
      _snack('Follow failed: $e');
    }
  }

  Future<void> showRatingSheet() async {
    final p = profile;
    final v = viewer;
    if (p == null || v == null || !canVisitorRate) return;

    double selected = myRating ?? 5;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AbleTheme.isDark(context) ? const Color(0xFF182437) : Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rate ${p.displayName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1.0;
                      return IconButton(
                        onPressed: () => setSheetState(() => selected = value),
                        icon: Icon(
                          value <= selected ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AbleColors.warning,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await submitRating(selected);
                    },
                    child: const Text('Submit Rating'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> submitRating(double rating) async {
    final p = profile;
    final v = viewer;
    if (p == null || v == null || !canVisitorRate) return;

    try {
      if (p.role == 'tutor') {
        await supabase.from('tutor_ratings').upsert({
          'client_id': v.id,
          'tutor_id': p.id,
          'rating': rating,
        });
      } else if (p.role == 'business') {
        await supabase.from('business_ratings').upsert({
          'client_id': v.id,
          'business_id': p.id,
          'rating': rating,
        });
      } else if (p.role == 'charity') {
        await supabase.from('charity_ratings').upsert({
          'client_id': v.id,
          'charity_id': p.id,
          'rating': rating,
        });
      }

      await loadProfile();
      _snack('Rating saved.');
    } catch (e) {
      _snack('Rating failed: $e');
    }
  }

  void _openMessagePlaceholder() {
    _snack('Messaging will be connected later.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;

    return AbleScaffold(
  title: 'Profile',
  currentIndex: 4,
  actions: const [],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _ErrorView(message: errorMessage!, onRetry: loadProfile)
              : p == null
                  ? _ErrorView(message: 'Profile not found.', onRetry: loadProfile)
                  : RefreshIndicator(
                      onRefresh: loadProfile,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        children: [
                          _ProfileHeader(
                            profile: p,
                            isOwnProfile: isOwnProfile,
                            canVisitorRate: canVisitorRate,
                            isFollowing: isFollowing,
                            myRating: myRating,
                            isSaving: isSaving,
                            onPickImage: pickProfileImage,
                            onEdit: editProfile,
                            onFollow: toggleFollow,
                            onMessage: _openMessagePlaceholder,
                            onRate: showRatingSheet,
                          ),
                          const SizedBox(height: 18),
                          _PostsPreview(role: p.role),
                        ],
                      ),
                    ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.canVisitorRate,
    required this.isFollowing,
    required this.myRating,
    required this.isSaving,
    required this.onPickImage,
    required this.onEdit,
    required this.onFollow,
    required this.onMessage,
    required this.onRate,
  });

  final _ProfileData profile;
  final bool isOwnProfile;
  final bool canVisitorRate;
  final bool isFollowing;
  final double? myRating;
  final bool isSaving;
  final VoidCallback onPickImage;
  final VoidCallback onEdit;
  final VoidCallback onFollow;
  final VoidCallback onMessage;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accent = AbleTheme.accent(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AbleTheme.glassCard(context),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: isOwnProfile ? onPickImage : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AbleTheme.iconBubble(context),
                          backgroundImage: profile.profilePicUrl != null && profile.profilePicUrl!.isNotEmpty
                              ? NetworkImage(profile.profilePicUrl!)
                              : null,
                          child: profile.profilePicUrl == null || profile.profilePicUrl!.isEmpty
                              ? Text(
                                  profile.username.isNotEmpty ? profile.username[0].toUpperCase() : 'A',
                                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: accent),
                                )
                              : null,
                        ),
                        if (isOwnProfile)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(color: AbleTheme.primary(context), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_rounded, size: 17, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
                        const SizedBox(height: 3),
                        Text('@${profile.username}', style: TextStyle(color: mutedColor, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(icon: Icons.verified_user_outlined, label: profile.roleLabel),
                            if (profile.location != null && profile.location!.isNotEmpty)
                              _InfoChip(icon: Icons.location_on_outlined, label: profile.location!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
             Row(
  children: [
    _StatBox(
      label: 'Posts',
      value: profile.postsCount.toString(),
    ),
    const SizedBox(width: 10),
    _StatBox(
      label: 'Followers',
      value: profile.followersCount.toString(),
    ),
    if (profile.role != 'client') ...[
      const SizedBox(width: 10),
      _StatBox(
        label: 'Rating',
        value: profile.averageRating.toStringAsFixed(1),
      ),
    ],
  ],
),
              const SizedBox(height: 18),
              if (profile.description.isNotEmpty)
                Text(profile.description, style: TextStyle(color: textColor, height: 1.5))
              else
                Text('No description yet.', style: TextStyle(color: mutedColor, height: 1.5)),
              const SizedBox(height: 20),
              if (isOwnProfile)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(isSaving ? 'Saving...' : 'Edit Profile'),
                  ),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onFollow,
                            icon: Icon(isFollowing ? Icons.check_rounded : Icons.person_add_alt_1_rounded),
                            label: Text(isFollowing ? 'Following' : 'Follow'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onMessage,
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const Text('Message'),
                          ),
                        ),
                      ],
                    ),
                    if (canVisitorRate) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onRate,
                          icon: const Icon(Icons.star_rounded, color: AbleColors.warning),
                          label: Text(myRating == null ? 'Rate out of 5' : 'Your rating: ${myRating!.toStringAsFixed(0)}/5'),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AbleTheme.panelFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AbleTheme.glassBorder(context)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AbleTheme.textPrimary(context))),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 12, color: AbleTheme.textMuted(context))),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AbleTheme.iconBubble(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AbleTheme.accent(context)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AbleTheme.accent(context))),
        ],
      ),
    );
  }
}

class _PostsPreview extends StatelessWidget {
  const _PostsPreview({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 190,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AbleTheme.glassCard(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AbleTheme.textPrimary(context))),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    'Posts layout will be connected later.',
                    style: TextStyle(color: AbleTheme.textMuted(context)),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AbleColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AbleTheme.textPrimary(context))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class _ViewerInfo {
  const _ViewerInfo({required this.role, required this.id, required this.email});

  final String role;
  final String id;
  final String email;
}

class _ProfileData {
  const _ProfileData({
    required this.role,
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.location,
    this.charityName,
    this.profileId,
    required this.description,
    this.profilePicUrl,
    required this.followersCount,
    required this.postsCount,
    required this.averageRating,
  });

  final String role;
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? location;
  final String? charityName;
  final String? profileId;
  final String description;
  final String? profilePicUrl;
  final int followersCount;
  final int postsCount;
  final double averageRating;

  String get displayName => role == 'charity' && charityName != null && charityName!.isNotEmpty ? charityName! : fullName;

  String get roleLabel {
    switch (role) {
      case 'client':
        return 'User';
      case 'tutor':
        return 'Tutor';
      case 'business':
        return 'Business';
      case 'charity':
        return 'Charity';
      default:
        return role;
    }
  }

  _ProfileData copyWith({String? profilePicUrl}) {
    return _ProfileData(
      role: role,
      id: id,
      fullName: fullName,
      username: username,
      email: email,
      location: location,
      charityName: charityName,
      profileId: profileId,
      description: description,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      followersCount: followersCount,
      postsCount: postsCount,
      averageRating: averageRating,
    );
  }
}

String _tableForRole(String role) {
  switch (role) {
    case 'client':
      return 'clients';
    case 'tutor':
      return 'tutors';
    case 'business':
      return 'businesses';
    case 'charity':
      return 'charities';
    default:
      throw Exception('Unknown role: $role');
  }
}

String _profileColumnForRole(String role) {
  switch (role) {
    case 'client':
      return 'client_id';
    case 'tutor':
      return 'tutor_id';
    case 'business':
      return 'business_id';
    case 'charity':
      return 'charity_id';
    default:
      throw Exception('Unknown role: $role');
  }
}

String _followedColumnForRole(String role) {
  switch (role) {
    case 'client':
      return 'followed_client_id';
    case 'tutor':
      return 'followed_tutor_id';
    case 'business':
      return 'followed_business_id';
    case 'charity':
      return 'followed_charity_id';
    default:
      throw Exception('Unknown role: $role');
  }
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
