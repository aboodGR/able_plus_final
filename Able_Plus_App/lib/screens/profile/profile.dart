import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:ableplusproject/Models/PostModel.dart';
import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/vip_provider.dart';
import 'package:ableplusproject/screens/Home/postcard.dart';
import 'package:ableplusproject/screens/Messages/chat_screen.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:ableplusproject/widgets/VipBadge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  _ProfileData? profile;
  bool isFollowing = false;
  double? myRating;

  List<PostModel> profilePosts = [];

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
      final viewer = await ref.read(viewerProvider.future);

      // Resolve which profile we're viewing
      String? role;
      String? id;

      if (widget.currentUserProfile) {
        if (viewer == null) throw Exception('No user is logged in.');
        role = viewer.role;
        id = viewer.id;
      } else {
        role = widget.role;
        id = widget.userId;
      }

      if (role == null || id == null) {
        throw Exception('Missing profile route information.');
      }

      // ─── ONE RPC call replaces 5+ queries ───
      profile = await _loadProfileViaRpc(role: role, id: id);
      if (profile == null) throw Exception('Profile not found.');
      final vipMap = await ref.read(activeVipProvidersProvider.future);
      final vipStatus = vipMap[vipKey(role, id)];
      profile = profile!.copyWith(
        isVip: vipStatus != null,
        vipExpiresAt: vipStatus?.expiresAt.toLocal(),
      );

      // Viewer-specific actions (follow + my rating) — runs in parallel.
      // For a logged-out viewer or own profile, this is essentially free.
      await _loadVisitorActions(viewer: viewer, p: profile!);

      // Posts list via the optimized posts_feed view + batched like check
      profilePosts = await _loadProfilePosts(viewer: viewer, p: profile!);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<_ProfileData?> _loadProfileViaRpc({
    required String role,
    required String id,
  }) async {
    final rows = await supabase.rpc(
      'user_profile',
      params: {'p_role': role, 'p_id': id},
    );

    if (rows is! List || rows.isEmpty) return null;
    final r = rows.first as Map<String, dynamic>;

    return _ProfileData(
      role: r['account_type']?.toString() ?? role,
      id: r['id'].toString(),
      authUserId: _cleanNullableText(r['auth_user_id']),
      fullName: r['full_name']?.toString() ?? 'Able+ User',
      username: r['username']?.toString() ?? 'username',
      email: r['email']?.toString() ?? '',
      location: _cleanNullableText(r['location']),
      latitude: _asNullableDouble(r['latitude'] ?? r['lat']),
      longitude: _asNullableDouble(r['longitude'] ?? r['lng']),
      charityName: _cleanNullableText(r['charity_name']),
      bio: _cleanNullableText(r['bio']),
      subjects: _parseSubjects(r['subjects'] ?? r['subject']),
      description: r['description']?.toString() ?? '',
      profilePicUrl: r['profile_pic_url']?.toString(),
      followersCount: _asInt(r['followers_count']),
      followingCount: _asInt(r['following_count']),
      postsCount: _asInt(r['posts_count']),
      averageRating: _asDouble(r['average_rating']),
      ratingCount: _asInt(r['rating_count']),
    );
  }

  Future<void> _loadVisitorActions({
    required AppViewer? viewer,
    required _ProfileData p,
  }) async {
    isFollowing = false;
    myRating = null;

    if (viewer == null || viewer.role != 'client') return;
    if (viewer.role == p.role && viewer.id == p.id) return;

    // ONE RPC for "is the viewer following this profile?"
    try {
      final follow = await supabase.rpc(
        'is_viewer_following',
        params: {'p_role': p.role, 'p_id': p.id},
      );
      isFollowing = follow == true;
    } catch (_) {}

    // ONE query for the viewer's rating, if applicable
    if (p.role == 'tutor' || p.role == 'business' || p.role == 'charity') {
      final ratingTable = '${p.role}_ratings';
      final fkCol = '${p.role}_id';

      final row = await supabase
          .from(ratingTable)
          .select('rating')
          .eq('client_id', viewer.id)
          .eq(fkCol, p.id)
          .maybeSingle();

      myRating = _asDouble(row?['rating']);
      if (myRating == 0) myRating = null;
    }
  }

  /// Loads this profile's posts via the optimized posts_feed view +
  /// a single batched like lookup. Reuses the same pattern as the home feed.
  Future<List<PostModel>> _loadProfilePosts({
    required AppViewer? viewer,
    required _ProfileData p,
  }) async {
    final feedRows = await supabase
        .from('posts_feed')
        .select(
          '*, media!media_post_id_fkey(file_url, file_type, media_type)',
        )
        .eq('author_type', p.role)
        .eq('author_id', p.id)
        .order('created_at', ascending: false);

    final likedSet = <String>{};
    if (viewer != null && (feedRows as List).isNotEmpty) {
      final postIds = feedRows.map((r) => r['id'].toString()).toList();
      final likedRows = await supabase
          .from('post_likes')
          .select('post_id')
          .inFilter('post_id', postIds)
          .eq(viewer.userColumn, viewer.id);
      for (final r in likedRows) {
        likedSet.add(r['post_id'].toString());
      }
    }

    final posts = <PostModel>[];
    for (final raw in feedRows as List) {
      final row = raw as Map<String, dynamic>;

      final media = (row['media'] as List?) ?? const [];
      final images = <String>[];
      String? videoUrl = row['video_url']?.toString();

      for (final m in media) {
        final mm = m as Map<String, dynamic>;
        if (mm['media_type'] != 'post') continue;
        final url = mm['file_url']?.toString();
        if (url == null || url.isEmpty) continue;
        if (mm['file_type'] == 'image') {
          images.add(url);
        } else if (mm['file_type'] == 'video' &&
            (videoUrl == null || videoUrl.isEmpty)) {
          videoUrl = url;
        }
      }

      final extra = row['image_url']?.toString();
      if (extra != null && extra.isNotEmpty && !images.contains(extra)) {
        images.add(extra);
      }

      final postId = row['id'].toString();

      posts.add(PostModel(
        id: postId,
        authorId: p.id,
        authorName: p.displayName,
        authorImage: p.profilePicUrl,
        content: row['content']?.toString() ?? '',
        images: images,
        videoUrl: (videoUrl != null && videoUrl.isNotEmpty) ? videoUrl : null,
        postType: p.role,
        tags: const [],
        createdAt: DateTime.parse(row['created_at'].toString()).toLocal(),
        likes: (row['likes_count'] as num?)?.toInt() ?? 0,
        comments: (row['comments_count'] as num?)?.toInt() ?? 0,
        isLiked: likedSet.contains(postId),
        donationLink: row['donation_link']?.toString(),
        isVip: p.isVip,
        vipExpiresAt: p.vipExpiresAt,
      ));
    }

    return posts;
  }

  bool get isOwnProfile {
    final p = profile;
    if (p == null) return false;

    final viewer = ref.read(viewerProvider).valueOrNull;
    if (viewer == null) return false;
    if (p.role != viewer.role) return false;

    final profileIds = <String>{
      p.id,
      if (p.authUserId != null && p.authUserId!.isNotEmpty) p.authUserId!,
    };

    final viewerIds = <String>{
      viewer.id,
      if (viewer.authUserId.isNotEmpty) viewer.authUserId,
    };

    return profileIds.any(viewerIds.contains);
  }

  bool get canVisitorRate {
    final p = profile;
    final viewer = ref.read(viewerProvider).valueOrNull;
    if (p == null || viewer == null) return false;
    if (p.role == 'client') return false;
    return !isOwnProfile && viewer.role == 'client';
  }

  bool get canFollow {
    final p = profile;
    final viewer = ref.read(viewerProvider).valueOrNull;
    if (p == null || viewer == null) return false;
    if (viewer.role != 'client') return false;
    return !isOwnProfile;
  }

  Future<void> pickProfileImage() async {
    // الصورة لا تُرفع ولا تُحفظ مباشرة.
    // نفتح شاشة تعديل البروفايل، وأي تغيير بالصورة يبقى Preview فقط
    // إلى أن يضغط المستخدم زر Save.
    await editProfile();
  }

  Future<_PickedProfileImage?> _pickProfileImageForEdit() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();

    return _PickedProfileImage(
      bytes: bytes,
      fileName: picked.name,
    );
  }

  Future<String> _uploadProfileImageAndGetUrl({
    required _ProfileData p,
    required Uint8List bytes,
  }) async {
    final path = '${p.role}/${p.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> editProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    if (p == null || !isOwnProfile) return;

    final nameController = TextEditingController(text: p.fullName);
    final usernameController = TextEditingController(text: p.username);
    final descriptionController = TextEditingController(text: p.description);
    final locationController = TextEditingController(text: p.location ?? '');
    final charityNameController =
        TextEditingController(text: p.charityName ?? '');

    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool sheetSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !sheetSaving,
      enableDrag: !sheetSaving,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            ImageProvider? avatarProvider;

            if (selectedImageBytes != null) {
              avatarProvider = MemoryImage(selectedImageBytes!);
            } else if (p.profilePicUrl != null && p.profilePicUrl!.isNotEmpty) {
              avatarProvider = NetworkImage(p.profilePicUrl!);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(sheetContext).size.height * 0.82,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AbleTheme.isDark(context)
                      ? const Color(0xFF182437)
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.editProfileTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: sheetSaving
                            ? null
                            : () async {
                                final picked = await _pickProfileImageForEdit();

                                if (picked == null) return;

                                setSheetState(() {
                                  selectedImageBytes = picked.bytes;
                                  selectedImageName = picked.fileName;
                                });
                              },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 58,
                              backgroundColor: AbleTheme.iconBubble(context),
                              backgroundImage: avatarProvider,
                              child: avatarProvider == null
                                  ? Text(
                                      p.username.isNotEmpty
                                          ? p.username[0].toUpperCase()
                                          : 'A',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        color: AbleTheme.accent(context),
                                      ),
                                    )
                                  : null,
                            ),
                            PositionedDirectional(
                              bottom: 2,
                              end: 2,
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AbleTheme.primary(context),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedImageName != null &&
                          selectedImageName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          selectedImageName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AbleTheme.textMuted(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        enabled: !sheetSaving,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.fullName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: usernameController,
                        enabled: !sheetSaving,
                        decoration: InputDecoration(
                          labelText: l10n.username,
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        enabled: !sheetSaving,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: l10n.description,
                          prefixIcon: const Icon(Icons.description_outlined),
                        ),
                      ),
                      if (p.role == 'business' || p.role == 'charity') ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: locationController,
                          enabled: !sheetSaving,
                          decoration: InputDecoration(
                            labelText: l10n.location,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                      if (p.role == 'charity') ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: charityNameController,
                          enabled: !sheetSaving,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.charityName,
                            prefixIcon:
                                const Icon(Icons.volunteer_activism_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: sheetSaving
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: sheetSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                sheetSaving ? l10n.saving : l10n.saveChanges,
                              ),
                              onPressed: sheetSaving
                                  ? null
                                  : () async {
                                      setSheetState(() {
                                        sheetSaving = true;
                                      });

                                      final saved = await _saveProfileEdit(
                                        fullName:
                                            nameController.text.trim(),
                                        username:
                                            usernameController.text.trim(),
                                        description: descriptionController.text
                                            .trim(),
                                        location:
                                            locationController.text.trim(),
                                        charityName: charityNameController.text
                                            .trim(),
                                        profileImageBytes: selectedImageBytes,
                                      );

                                      if (!mounted ||
                                          !sheetContext.mounted) {
                                        return;
                                      }

                                      if (saved) {
                                        Navigator.pop(sheetContext);
                                      } else {
                                        setSheetState(() {
                                          sheetSaving = false;
                                        });
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    usernameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    charityNameController.dispose();
  }

  Future<bool> _saveProfileEdit({
    required String fullName,
    required String username,
    required String description,
    required String location,
    required String charityName,
    Uint8List? profileImageBytes,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    if (p == null) return false;

    if (fullName.isEmpty || username.isEmpty) {
      _snack(l10n.nameAndUsernameRequired);
      return false;
    }
    if (RegExp(r'[0-9]').hasMatch(fullName)) {
      _snack(l10n.fullNameNoNumbers);
      return false;
    }
    if (p.role == 'charity' && RegExp(r'[0-9]').hasMatch(charityName)) {
      _snack(l10n.charityNameNoNumbers);
      return false;
    }

    if (p.role == 'business' && location.isEmpty) {
      _snack(l10n.locationRequired);
      return false;
    }
    if (p.role == 'charity' && (location.isEmpty || charityName.isEmpty)) {
      _snack(l10n.charityNameAndLocationRequired);
      return false;
    }

    setState(() => isSaving = true);

    try {
      final accountUpdate = <String, dynamic>{
        'full_name': fullName,
        'username': username,
      };

      if (p.role == 'business') {
        accountUpdate['location'] = location;
      }

      if (p.role == 'charity') {
        accountUpdate['location'] = location;
        accountUpdate['charity_name'] = charityName;
      }

      await supabase
          .from(_tableForRole(p.role))
          .update(accountUpdate)
          .eq('id', p.id);

      await _ensureProfileRowExists(p);

      final profileUpdate = <String, dynamic>{
        'description': description,
      };

      if (profileImageBytes != null) {
        final newImageUrl = await _uploadProfileImageAndGetUrl(
          p: p,
          bytes: profileImageBytes,
        );

        profileUpdate['profile_pic_url'] = newImageUrl;
      }

      await supabase
          .from('profiles')
          .update(profileUpdate)
          .eq(_profileColumnForRole(p.role), p.id);

      ref.invalidate(viewerProvider);
      await loadProfile();
      _snack(l10n.profileUpdated);

      return true;
    } catch (e) {
      _snack('${l10n.saveFailed}: $e');
      return false;
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _ensureProfileRowExists(_ProfileData p) async {
    final column = _profileColumnForRole(p.role);
    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq(column, p.id)
        .maybeSingle();
    if (existing != null) return;
    await supabase.from('profiles').insert({column: p.id});
  }

  Future<void> toggleFollow() async {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    final viewer = await ref.read(viewerProvider.future);
    if (p == null || viewer == null) return;
    if (viewer.role != 'client' || isOwnProfile) return;

    final followedColumn = _followedColumnForRole(p.role);
    if (followedColumn.isEmpty) return;

    try {
      final deleted = await supabase
          .from('follows')
          .delete()
          .eq('follower_client_id', viewer.id)
          .eq(followedColumn, p.id)
          .select('id');

      if (deleted.isEmpty) {
        await supabase.from('follows').insert({
          'follower_client_id': viewer.id,
          followedColumn: p.id,
        });

        // Send follow notification (mirrors Post_provider's logic).
        // Honestly identifies the viewer per the new RLS rule.
        try {
          final target = await supabase
              .from('app_users')
              .select('auth_user_id')
              .eq('id', p.id)
              .eq('account_type', p.role)
              .maybeSingle();
          final receiverAuthId = target?['auth_user_id']?.toString();
          if (receiverAuthId != null &&
              receiverAuthId != viewer.authUserId) {
            await supabase.from('notifications').insert({
              'type': 'follow',
              'title': 'New follower',
              'message': '${viewer.username} started following you',
              'related_user_id': viewer.authUserId,
              'receiver_id': receiverAuthId,
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (_) {}
      }

      await loadProfile();
    } catch (e) {
      _snack('${l10n.followFailed}: $e');
    }
  }

  Future<void> openMessage() async {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    final viewer = await ref.read(viewerProvider.future);
    if (p == null || viewer == null) {
      _snack(l10n.pleaseLoginFirst);
      return;
    }
    if (isOwnProfile) return;

    try {
      final conversationId = await supabase.rpc(
        'get_or_create_conversation',
        params: {
          'p_my_id': viewer.id,
          'p_my_type': viewer.role,
          'p_other_id': p.id,
          'p_other_type': p.role,
        },
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId.toString(),
            otherName: p.displayName,
            otherImage: p.profilePicUrl,
            otherId: p.id,
            otherType: p.role,
          ),
        ),
      );
    } catch (e) {
      _snack('${l10n.openChatFailed}: $e');
    }
  }

  Future<void> openReportUser() async {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    final viewer = await ref.read(viewerProvider.future);
    if (p == null || viewer == null) {
      _snack(l10n.pleaseLoginFirst);
      return;
    }
    if (isOwnProfile) return;

    final messageController = TextEditingController();
    bool sending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AbleTheme.isDark(context)
                    ? const Color(0xFF182437)
                    : Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Text(l10n.reportName(p.displayName),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: messageController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: l10n.reportReasonHint,
                      prefixIcon: const Icon(Icons.flag_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: sending
                        ? null
                        : () async {
                            final msg = messageController.text.trim();
                            if (msg.isEmpty) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                    content: Text(l10n.pleaseWriteReason)),
                              );
                              return;
                            }
                            setSheetState(() => sending = true);
                            try {
                              await supabase.from('user_reports').insert({
                                'reported_user_id': p.id,
                                'reported_by': viewer.id,
                                'message': msg,
                                'status': 'pending',
                              });
                              if (!sheetContext.mounted) return;
                              Navigator.pop(sheetContext);
                              _snack(l10n.reportSubmitted);
                            } catch (e) {
                              if (!sheetContext.mounted) return;
                              setSheetState(() => sending = false);
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${l10n.couldNotSendReport}: $e')),
                              );
                            }
                          },
                    icon: const Icon(Icons.send_rounded),
                    label: Text(sending ? l10n.sending : l10n.submitReport),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> openProfileMenu() async {
    final l10n = AppLocalizations.of(context)!;
    if (isOwnProfile) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = AbleTheme.isDark(context);
        final sheetColor = isDark ? const Color(0xFF182437) : Colors.white;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined,
                      color: Colors.orange),
                  title: Text(l10n.reportUser,
                      style: const TextStyle(color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openReportUser();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showRatingSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    if (p == null || !canVisitorRate) return;

    double selected = myRating ?? 5;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AbleTheme.isDark(context)
                  ? const Color(0xFF182437)
                  : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.rateName(p.displayName),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1.0;
                    return IconButton(
                      onPressed: () =>
                          setSheetState(() => selected = value),
                      icon: Icon(
                        value <= selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
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
                  child: Text(l10n.submitRating),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        });
      },
    );
  }

 Future<void> submitRating(double rating) async {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    final viewer = await ref.read(viewerProvider.future);
    if (p == null || viewer == null || !canVisitorRate) return;

    try {
      final table = '${p.role}_ratings';
      final fkCol = '${p.role}_id';

      // Try UPDATE first (preserves any existing comment).
      final updated = await supabase
          .from(table)
          .update({'rating': rating})
          .eq('client_id', viewer.id)
          .eq(fkCol, p.id)
          .select('rating');

      // If no existing row, INSERT a fresh rating with no comment.
      if (updated.isEmpty) {
        await supabase.from(table).insert({
          'client_id': viewer.id,
          fkCol: p.id,
          'rating': rating,
        });
      }

      await loadProfile();
      _snack(l10n.ratingSaved);
    } catch (e) {
      _snack('${l10n.ratingFailed}: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;

    return AbleScaffold(
      title: l10n.profile,
      currentIndex: 4,
      actions: const [],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _ErrorView(message: errorMessage!, onRetry: loadProfile)
              : p == null
                  ? _ErrorView(
                      message: l10n.profileNotFound,
                      onRetry: loadProfile,
                    )
                  : RefreshIndicator(
                      onRefresh: loadProfile,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        children: [
                          _ProfileHeader(
                            profile: p,
                            isOwnProfile: isOwnProfile,
                            canVisitorRate: canVisitorRate,
                            canFollow: canFollow,
                            isFollowing: isFollowing,
                            myRating: myRating,
                            isSaving: isSaving,
                            onPickImage: pickProfileImage,
                            onEdit: editProfile,
                            onFollow: toggleFollow,
                            onMessage: openMessage,
                            onRate: showRatingSheet,
                            onMenu: openProfileMenu,
                            onFollowersTap: () => context.push(
                              '/profile/${p.role}/${p.id}/connections?tab=followers',
                            ),
                            onFollowingTap: () => context.push(
                              '/profile/${p.role}/${p.id}/connections?tab=following',
                            ),
                          ),
                          const SizedBox(height: 18),
                          _PostsSection(posts: profilePosts),
                        ],
                      ),
                    ),
    );
  }
}

// ─────────────────────────────────────────────
// Posts section — now uses the shared, optimized PostCard.
// ─────────────────────────────────────────────

class _PostsSection extends StatelessWidget {
  const _PostsSection({required this.posts});
  final List<PostModel> posts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AbleTheme.glassCard(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TtsWrapper(
                text: l10n.posts,
                child: Text(
                  l10n.posts,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AbleTheme.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (posts.isEmpty)
                SizedBox(
                  height: 110,
                  child: Center(
                    child: Text(
                      l10n.noPostsYetPeriod,
                      style: TextStyle(color: AbleTheme.textMuted(context)),
                    ),
                  ),
                )
              else
                ...posts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PostCard(post: post),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile header (unchanged from before, minus dead code)
// ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.canVisitorRate,
    required this.canFollow,
    required this.isFollowing,
    required this.myRating,
    required this.isSaving,
    required this.onPickImage,
    required this.onEdit,
    required this.onFollow,
    required this.onMessage,
    required this.onRate,
    required this.onMenu,
    required this.onFollowersTap,
    required this.onFollowingTap,
  });

  final _ProfileData profile;
  final bool isOwnProfile;
  final bool canVisitorRate;
  final bool canFollow;
  final bool isFollowing;
  final double? myRating;
  final bool isSaving;
  final VoidCallback onPickImage;
  final VoidCallback onEdit;
  final VoidCallback onFollow;
  final VoidCallback onMessage;
  final VoidCallback onRate;
  final VoidCallback onMenu;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accent = AbleTheme.accent(context);
    final displayLocation = _profileDisplayLocation(context, profile);
    final displaySubjects = _parseSubjects(profile.subjects);

    return VipGoldFrame(
      isVip: profile.isVip,
      radius: 31,
      child: ClipRRect(
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
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AbleTheme.iconBubble(context),
                    backgroundImage: profile.profilePicUrl != null &&
                            profile.profilePicUrl!.isNotEmpty
                        ? NetworkImage(profile.profilePicUrl!)
                        : null,
                    child: profile.profilePicUrl == null ||
                            profile.profilePicUrl!.isEmpty
                        ? Text(
                            profile.username.isNotEmpty
                                ? profile.username[0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TtsWrapper(
                      text: [
                        profile.displayName,
                        '@${profile.username}',
                        profile.roleLabel(l10n),
                        if (displayLocation.isNotEmpty) displayLocation,
                      ].join('. '),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            )),
                        const SizedBox(height: 3),
                        Text('@${profile.username}',
                            style: TextStyle(
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.verified_user_outlined,
                              label: profile.roleLabel(l10n),
                            ),
                            if (profile.isVip) const VipBadge(),
                            if (displayLocation.isNotEmpty)
                              _InfoChip(
                                icon: Icons.location_on_outlined,
                                label: displayLocation,
                              ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  ),
                  if (!isOwnProfile)
                    IconButton(
                      tooltip: l10n.more,
                      icon: Icon(Icons.more_vert_rounded,
                          color: AbleTheme.textMuted(context)),
                      onPressed: onMenu,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _StatBox(
                      label: l10n.posts,
                      value: profile.postsCount.toString()),
                  const SizedBox(width: 10),
                  _StatBox(
                    label: l10n.followers,
                    value: profile.followersCount.toString(),
                    onTap: onFollowersTap,
                  ),
                  // Following count only applies to clients (only clients
                  // can follow). On business/tutor/charity profiles the
                  // count would always be 0 and confuse the viewer, so
                  // hide it entirely. Followers count still shows for
                  // everyone — they all have followers.
                  if (profile.role == 'client') ...[
                    const SizedBox(width: 10),
                    _StatBox(
                      label: l10n.following,
                      value: profile.followingCount.toString(),
                      onTap: onFollowingTap,
                    ),
                  ],
                  if (profile.role != 'client') ...[
                    const SizedBox(width: 10),
                    _StatBox(
                      label: l10n.rating,
                      value: profile.averageRating.toStringAsFixed(1),
                    ),
                  ],
                ],
              ),
              if (profile.role == 'tutor' && displaySubjects.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: displaySubjects
                      .map((s) => Chip(label: Text(s)))
                      .toList(),
                ),
              ],
              const SizedBox(height: 18),
              if (profile.role == 'tutor' && (profile.bio ?? '').isNotEmpty) ...[
                Text(
                  profile.bio!,
                  style: TextStyle(color: textColor, height: 1.5),
                ),
                const SizedBox(height: 10),
              ],
              TtsWrapper(
                text: profile.description.isNotEmpty
                    ? profile.description
                    : l10n.noDescriptionYet,
                child: Text(
                  profile.description.isNotEmpty
                      ? profile.description
                      : l10n.noDescriptionYet,
                  style: TextStyle(
                    color: profile.description.isNotEmpty
                        ? textColor
                        : mutedColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isOwnProfile)
                TtsWrapper(
                  text: isSaving ? l10n.saving : l10n.editProfile,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(isSaving ? l10n.saving : l10n.editProfile),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        if (canFollow) ...[
                          Expanded(
                            child: TtsWrapper(
                              text: isFollowing ? l10n.following : l10n.follow,
                              child: ElevatedButton.icon(
                                onPressed: onFollow,
                                icon: Icon(
                                  isFollowing
                                      ? Icons.check_rounded
                                      : Icons.person_add_alt_1_rounded,
                                ),
                                label: Text(
                                    isFollowing ? l10n.following : l10n.follow),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: TtsWrapper(
                            text: l10n.message,
                            child: OutlinedButton.icon(
                              onPressed: onMessage,
                              icon: const Icon(
                                  Icons.chat_bubble_outline_rounded),
                              label: Text(l10n.message),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (canVisitorRate) ...[
                      const SizedBox(height: 10),
                      TtsWrapper(
                        text: myRating == null
                            ? l10n.rateOutOfFive
                            : l10n.yourRating(myRating!.toStringAsFixed(0)),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onRate,
                            icon: const Icon(Icons.star_rounded,
                                color: AbleColors.warning),
                            label: Text(
                              myRating == null
                                  ? l10n.rateOutOfFive
                                  : l10n.yourRating(
                                      myRating!.toStringAsFixed(0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AbleTheme.panelFill(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AbleTheme.glassBorder(context)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AbleTheme.textPrimary(context),
              )),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: AbleTheme.textMuted(context),
              )),
        ],
      ),
    );
    return Expanded(
      child: TtsWrapper(
        text: '$value $label',
        child: onTap == null
            ? content
            : InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: content,
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
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AbleTheme.accent(context),
              )),
        ],
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AbleColors.danger),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AbleTheme.textPrimary(context))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
          ],
        ),
      ),
    );
  }
}

class _PickedProfileImage {
  const _PickedProfileImage({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

// ─────────────────────────────────────────────
// Local data class
// ─────────────────────────────────────────────

class _ProfileData {
  const _ProfileData({
    required this.role,
    required this.id,
    this.authUserId,
    required this.fullName,
    required this.username,
    required this.email,
    this.location,    
    this.latitude,
    this.longitude,
    this.charityName,
    this.bio,
    this.subjects = const [],
    required this.description,
    this.profilePicUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.averageRating,
    this.ratingCount = 0,
    this.isVip = false,
    this.vipExpiresAt,
  });

  final String role;
  final String id;
  final String? authUserId;
  final String fullName;
  final String username;
  final String email;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? charityName;
  final String? bio;
  final List<String> subjects;
  final String description;
  final String? profilePicUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final double averageRating;
  final int ratingCount;
  final bool isVip;
  final DateTime? vipExpiresAt;

  String get displayName =>
      role == 'charity' && charityName != null && charityName!.isNotEmpty
          ? charityName!
          : fullName;

  String roleLabel(AppLocalizations l10n) {
    switch (role) {
      case 'client':
        return l10n.roleClient;
      case 'tutor':
        return l10n.roleTutor;
      case 'business':
        return l10n.roleBusiness;
      case 'charity':
        return l10n.roleCharity;
      default:
        return role;
    }
  }

  _ProfileData copyWith({
  String? profilePicUrl,
  bool? isVip,
  DateTime? vipExpiresAt,
  int? followersCount,
  int? followingCount,
}) {
  return _ProfileData(
    role: role,
    id: id,
    authUserId: authUserId,
    fullName: fullName,
    username: username,
    email: email,
    location: location,
    latitude: latitude,
    longitude: longitude,
    charityName: charityName,
    bio: bio,
    subjects: subjects,
    description: description,
    profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount ?? this.followingCount,
    postsCount: postsCount,
    averageRating: averageRating,
    ratingCount: ratingCount,
    isVip: isVip ?? this.isVip,
    vipExpiresAt: vipExpiresAt ?? this.vipExpiresAt,
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
      return '';
  }
}


String? _cleanNullableText(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') return null;

  return text;
}

List<String> _parseSubjects(dynamic raw) {
  if (raw == null) return const [];

  if (raw is Iterable) {
    final result = <String>[];

    for (final item in raw) {
      result.addAll(_parseSubjects(item));
    }

    return result
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
        .toSet()
        .toList();
  }

  var text = raw.toString().trim();

  if (text.isEmpty ||
      text.toLowerCase() == 'null' ||
      text == '[]' ||
      text == '{}') {
    return const [];
  }

  if (text.startsWith('[') && text.endsWith(']')) {
    try {
      final decoded = jsonDecode(text);

      if (decoded is Iterable) {
        return _parseSubjects(decoded);
      }
    } catch (_) {
      // Continue with fallback parsing below.
    }
  }

  if ((text.startsWith('[') && text.endsWith(']')) ||
      (text.startsWith('{') && text.endsWith('}'))) {
    text = text.substring(1, text.length - 1).trim();
  }

  if (text.isEmpty) return const [];

  return text
      .split(',')
      .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
      .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
      .toSet()
      .toList();
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;

  if (value is num) return value.toDouble();

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') return null;

  return double.tryParse(text);
}

String _profileDisplayLocation(BuildContext context, _ProfileData profile) {
  if (profile.role == 'tutor') {
    final governorate = _governorateFromCoordinates(
      latitude: profile.latitude,
      longitude: profile.longitude,
      isArabic: AppLocalizations.of(context)!.localeName == 'ar',
    );

    if (governorate.isNotEmpty) return governorate;

    final fallback = profile.location?.trim() ?? '';

    if (_looksLikeCoordinates(fallback)) return '';

    return fallback;
  }

  return profile.location?.trim() ?? '';
}

bool _looksLikeCoordinates(String value) {
  final text = value.trim();

  if (text.isEmpty) return false;

  final parts = text.split(',');

  if (parts.length != 2) return false;

  return double.tryParse(parts[0].trim()) != null &&
      double.tryParse(parts[1].trim()) != null;
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
  _JordanGovernorate(en: 'Tafilah', ar: 'الطفيلة', lat: 30.8333, lng: 35.6000),
  _JordanGovernorate(en: 'Ma’an', ar: 'معان', lat: 30.1962, lng: 35.7341),
  _JordanGovernorate(en: 'Aqaba', ar: 'العقبة', lat: 29.5319, lng: 35.0061),
];

String _governorateFromCoordinates({
  required double? latitude,
  required double? longitude,
  required bool isArabic,
}) {
  if (latitude == null || longitude == null) return '';

  _JordanGovernorate nearest = _jordanGovernorates.first;
  double bestDistance = double.infinity;

  for (final governorate in _jordanGovernorates) {
    final distance = _distanceKm(
      latitude,
      longitude,
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

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}