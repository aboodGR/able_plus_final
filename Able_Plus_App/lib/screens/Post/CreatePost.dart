import 'dart:io';
import 'dart:typed_data';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class _AccountInfo {
  final String table;
  final String id;
  final String tagLabel;
  final IconData tagIcon;

  const _AccountInfo({
    required this.table,
    required this.id,
    required this.tagLabel,
    required this.tagIcon,
  });
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController donationLinkController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  // ==== Image state ====
  File? selectedImage;
  Uint8List? selectedImageBytes;
  XFile? pickedImage;

  // ==== Video state ====
  File? selectedVideo;
  Uint8List? selectedVideoBytes;
  XFile? pickedVideo;
  VideoPlayerController? _videoController;
  bool _videoInitializing = false;

  bool isLoading = false;
  bool isAccountLoading = true;
  String? accountLoadError;
  String? createError;

  _AccountInfo? currentAccount;

  // True => post goes to community_posts, false => home (posts table).
  // Only `clients` are allowed to toggle this on; for every other
  // role we keep this false and hide the toggle entirely.
  bool _isCommunityPost = false;

  bool get _isClient => currentAccount?.table == 'clients';
  bool get _isCharity => currentAccount?.table == 'charities';

  /// Display label for the account tag. The stored value (tagLabel) stays
  /// English/canonical because it is written to community_posts.user_tag;
  /// only the on-screen chip is localized.
  String _displayTag(AppLocalizations l10n, String? table) {
    switch (table) {
      case 'clients':
        return l10n.tagUser;
      case 'tutors':
        return l10n.tagEducational;
      case 'businesses':
        return l10n.tagBusiness;
      case 'charities':
        return l10n.tagCharity;
      default:
        return l10n.accountLoading;
    }
  }

  @override
  void initState() {
    super.initState();
    _initAccount();
  }

  @override
  void dispose() {
    controller.dispose();
    donationLinkController.dispose();
    _videoController?.dispose();
    super.dispose();
  }


  Future<void> _initAccount() async {
    setState(() {
      isAccountLoading = true;
      accountLoadError = null;
    });
    try {
      final account = await _loadCurrentAccount();
      if (!mounted) return;
      setState(() {
        currentAccount = account;
        isAccountLoading = false;
        if (account.table != 'clients') {
          _isCommunityPost = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isAccountLoading = false;
        accountLoadError =
            'Could not load your posting account. The current_viewer() SQL RPC may be missing or blocked.\n$e';
      });
    }
  }

  Future<_AccountInfo> _loadCurrentAccount() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      throw Exception('No user is logged in. Please login first.');
    }

    // Use the same SQL identity RPC used by the rest of the app. This avoids
    // four sequential email lookups and exposes an SQL/RLS failure clearly.
    final rows = await supabase.rpc('current_viewer');
    if (rows is! List || rows.isEmpty) {
      throw Exception('current_viewer() returned no account row.');
    }
    final row = rows.first as Map<String, dynamic>;
    final role = row['account_type']?.toString() ?? '';
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) throw Exception('current_viewer() returned no provider id.');

    switch (role) {
      case 'client':
        return _AccountInfo(table: 'clients', id: id, tagLabel: 'User', tagIcon: Icons.person_outline);
      case 'tutor':
        return _AccountInfo(table: 'tutors', id: id, tagLabel: 'Educational', tagIcon: Icons.school_outlined);
      case 'business':
        return _AccountInfo(table: 'businesses', id: id, tagLabel: 'Business', tagIcon: Icons.storefront_outlined);
      case 'charity':
        return _AccountInfo(table: 'charities', id: id, tagLabel: 'Charity', tagIcon: Icons.volunteer_activism_outlined);
      default:
        throw Exception('Unsupported account type from current_viewer(): $role');
    }
  }

  // ===================== IMAGE PICKING =====================

  Future<void> setPickedImage(XFile image) async {
    pickedImage = image;
    if (kIsWeb) {
      selectedImageBytes = await image.readAsBytes();
      selectedImage = null;
    } else {
      selectedImage = File(image.path);
      selectedImageBytes = null;
    }
    setState(() {});
  }

  Future<void> pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                if (!kIsWeb)
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: Text(l10n.camera),
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (image != null) await setPickedImage(image);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.gallery),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) await setPickedImage(image);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== VIDEO PICKING =====================

  Future<void> setPickedVideo(XFile video) async {
    setState(() {
      _videoInitializing = true;
      pickedVideo = video;
    });

    await _videoController?.dispose();
    _videoController = null;

    if (kIsWeb) {
      selectedVideoBytes = await video.readAsBytes();
      selectedVideo = null;
    } else {
      selectedVideo = File(video.path);
      selectedVideoBytes = null;

      _videoController = VideoPlayerController.file(selectedVideo!);
      try {
        await _videoController!.initialize();
        _videoController!.setLooping(true);
      } catch (_) {
        // ignore
      }
    }

    if (!mounted) return;
    setState(() {
      _videoInitializing = false;
    });
  }

  Future<void> pickVideo() async {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                if (!kIsWeb)
                  ListTile(
                    leading: const Icon(Icons.videocam_outlined),
                    title: Text(l10n.recordVideo),
                    onTap: () async {
                      Navigator.pop(context);
                      final video = await picker.pickVideo(
                        source: ImageSource.camera,
                        maxDuration: const Duration(minutes: 2),
                      );
                      if (video != null) await setPickedVideo(video);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: Text(l10n.galleryVideo),
                  onTap: () async {
                    Navigator.pop(context);
                    final video = await picker.pickVideo(
                      source: ImageSource.gallery,
                      maxDuration: const Duration(minutes: 2),
                    );
                    if (video != null) await setPickedVideo(video);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    pickedVideo = null;
    selectedVideo = null;
    selectedVideoBytes = null;
    setState(() {});
  }

  // ===================== UPLOAD =====================

  Future<String?> _uploadFile({
    required SupabaseClient supabase,
    required String accountId,
    required String folder,
    required String extension,
    required String contentType,
    required File? file,
    required Uint8List? bytes,
  }) async {
    final fileName =
        '${accountId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final filePath = '$folder/$fileName';

    if (kIsWeb) {
      if (bytes == null) throw Exception('File bytes are empty.');
      await supabase.storage
          .from('post-media')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
    } else {
      if (file == null) throw Exception('File is empty.');
      await supabase.storage
          .from('post-media')
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
    }

    return supabase.storage.from('post-media').getPublicUrl(filePath);
  }

  // =====================================================================
  // استبدل دالة createPost() الحالية في CreatePostScreen بهذي الدالة
  // =====================================================================

  Future<void> createPost() async {
    final l10n = AppLocalizations.of(context)!;
    final content = controller.text.trim();

    if (content.isEmpty && pickedImage == null && pickedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addDescriptionImageOrVideo)),
      );
      return;
    }

    if (currentAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.accountStillLoading)));
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
      createError = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final account = currentAccount!;
      final authUser = supabase.auth.currentUser;

      // ================= Upload Image =================
      String? imageUrl;
      if (pickedImage != null) {
        imageUrl = await _uploadFile(
          supabase: supabase,
          accountId: account.id,
          folder: 'images',
          extension: 'jpg',
          contentType: 'image/jpeg',
          file: selectedImage,
          bytes: selectedImageBytes,
        );
      }

      // ================= Upload Video =================
      String? videoUrl;
      if (pickedVideo != null) {
        final originalName = pickedVideo!.name.toLowerCase();

        String ext = 'mp4';
        String ct = 'video/mp4';

        if (originalName.endsWith('.mov')) {
          ext = 'mov';
          ct = 'video/quicktime';
        } else if (originalName.endsWith('.webm')) {
          ext = 'webm';
          ct = 'video/webm';
        }

        videoUrl = await _uploadFile(
          supabase: supabase,
          accountId: account.id,
          folder: 'videos',
          extension: ext,
          contentType: ct,
          file: selectedVideo,
          bytes: selectedVideoBytes,
        );
      }

      // =========================================================
      // Community Post -> community_posts
      // (Defense in depth: even if _isCommunityPost slipped to true
      //  for a non-client account, block the insert here so the
      //  community feed stays for regular users only.)
      // =========================================================
      if (_isCommunityPost) {
        if (account.table != 'clients') {
          throw Exception(
            'Only regular users can post to the find_and_share feed.',
          );
        }

        final Map<String, dynamic> communityData = {
          'user_id': authUser?.id, // UUID from auth.users
          'account_id': account.id, // UUID from clients/tutors/etc.
          'account_type': account.table,
          'description': content.isEmpty ? 'Shared a post.' : content,
          'image_url': imageUrl,
          'video_url': videoUrl,
          'post_type': 'giveaway',
          'user_tag': account.tagLabel,
          'created_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('community_posts').insert(communityData);
      }
      // =========================================================
      // Home Post -> posts
      // =========================================================
      else {
        final Map<String, dynamic> postData = {
          'content': content.isEmpty ? 'Shared a post.' : content,
          'image_url': imageUrl,
          'video_url': videoUrl,
          'created_at': DateTime.now().toIso8601String(),
        };

        // For charity accounts: optionally attach a donation link.
        // Normalised (https:// prefix added if missing) so the feed
        // button can launch it without extra parsing.
        if (account.table == 'charities') {
          final raw = donationLinkController.text.trim();
          if (raw.isNotEmpty) {
            var normalized = raw;
            if (!normalized.startsWith('http://') &&
                !normalized.startsWith('https://')) {
              normalized = 'https://$normalized';
            }
            postData['donation_link'] = normalized;
          }
        }

        // UUID values (no int.parse)
        switch (account.table) {
          case 'clients':
            postData['client_id'] = account.id;
            break;

          case 'tutors':
            postData['tutor_id'] = account.id;
            break;

          case 'charities':
            postData['charity_id'] = account.id;
            break;

          case 'businesses':
            postData['business_id'] = account.id;
            break;

          default:
            throw Exception('Unknown account type: ${account.table}');
        }

        await supabase.from('posts').insert(postData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCommunityPost
                ? l10n.postedToCommunity
                : l10n.postCreatedSuccess,
          ),
        ),
      );

      // Use context.pop (go_router) so the value flows back to the
      // `context.push<bool>` call in AbleScaffold. Plain Navigator.pop
      // does not deliver the result through go_router's Future, which is
      // why the feed wasn't refreshing.
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => createError = '${l10n.error}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  // ===================== UI HELPERS =====================

  Widget buildSelectedImage() {
    if (kIsWeb && selectedImageBytes != null) {
      return Image.memory(
        selectedImageBytes!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    if (!kIsWeb && selectedImage != null) {
      return Image.file(
        selectedImage!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox();
  }

  Widget buildAutoTag({required Color accentColor, required Color titleColor}) {
    final l10n = AppLocalizations.of(context)!;
    final account = currentAccount;
    return TtsWrapper(
      text: _displayTag(l10n, account?.table),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            account?.tagIcon ?? Icons.person_outline,
            size: 18,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Text(
            _displayTag(l10n, account?.table),
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// 👇 تاج Community (الزر الرئيسي)
  Widget _buildCommunityToggle({
    required bool isDark,
    required Color titleColor,
    required Color mutedColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    const communityColor = Color(0xFF2E9E5B);

    return TtsWrapper(
      text: l10n.findAndShare,
      child: GestureDetector(
      onTap: () => setState(() => _isCommunityPost = !_isCommunityPost),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _isCommunityPost
              ? communityColor.withOpacity(isDark ? 0.25 : 0.15)
              : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.78)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isCommunityPost
                ? communityColor
                : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08)),
            width: _isCommunityPost ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isCommunityPost ? Icons.groups_rounded : Icons.groups_outlined,
              size: 20,
              color: _isCommunityPost ? communityColor : mutedColor,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.findAndShare,
              style: TextStyle(
                color: _isCommunityPost ? communityColor : titleColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _isCommunityPost ? Icons.check_circle : Icons.add_circle_outline,
              size: 18,
              color: _isCommunityPost
                  ? communityColor
                  : mutedColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget buildImagePicker({
    required Color cardColor,
    required Color cardBorder,
    required Color iconBg,
    required Color accentColor,
    required Color titleColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TtsWrapper(
      text: l10n.addAPhoto,
      child: GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: pickedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.addAPhoto,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kIsWeb ? l10n.tapToChoose : l10n.cameraOrGallery,
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: buildSelectedImage(),
                    ),
                  ),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          pickedImage = null;
                          selectedImage = null;
                          selectedImageBytes = null;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
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

  Widget buildVideoPicker({
    required Color cardColor,
    required Color cardBorder,
    required Color iconBg,
    required Color accentColor,
    required Color titleColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TtsWrapper(
      text: l10n.addAVideo,
      child: GestureDetector(
      onTap: pickVideo,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: pickedVideo == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam_outlined,
                      size: 32,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.addAVideo,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.upTo2Minutes,
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildVideoPreview(accentColor),
                    ),
                  ),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: GestureDetector(
                      onTap: _removeVideo,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (!kIsWeb &&
                      _videoController != null &&
                      _videoController!.value.isInitialized)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _videoController!.value.isPlaying
                                  ? 0.0
                                  : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
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

  Widget _buildVideoPreview(Color accent) {
    final l10n = AppLocalizations.of(context)!;
    if (_videoInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!kIsWeb &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 50, color: accent),
            const SizedBox(height: 8),
            Text(
              pickedVideo?.name ?? l10n.videoSelected,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);
    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final mutedColor = isDark
        ? AbleColors.darkTextMuted
        : AbleColors.lightTextMuted;
    final accentColor = isDark
        ? AbleColors.darkSecondary
        : AbleColors.lightPrimaryDark;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.78);
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.65);
    final iconBg = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE8F7FC);

    final buttonGradient = isDark
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0B2C66), Color(0xFF1551A8), Color(0xFF6ED4E6)],
          )
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0B82D2), Color(0xFF45AEDD), Color(0xFF7BD8E8)],
          );

    final buttonLabel = _isCommunityPost ? l10n.postToCommunity : l10n.postToHome;

    return AbleScaffold(
      title: l10n.createPostTitle,
      currentIndex: 2,
      showBackButton: true,
      body: isAccountLoading
          ? const Center(child: CircularProgressIndicator())
          : accountLoadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storage_rounded, size: 48, color: Colors.orange),
                        const SizedBox(height: 12),
                        Text(accountLoadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _initAccount,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TtsWrapper(
                        text: l10n.createAPost,
                        child: Text(
                          l10n.createAPost,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TtsWrapper(
                        text: _isCommunityPost
                            ? l10n.communityPostNotice
                            : l10n.homePostNotice,
                        child: Text(
                          _isCommunityPost
                              ? l10n.communityPostNotice
                              : l10n.homePostNotice,
                          style: TextStyle(color: mutedColor, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Row containing the account tag and, for
                      // `clients` only, the Community toggle.
                      // Tutors / businesses / charities don't see
                      // the toggle so they cannot post to community.
                      Row(
                        children: [
                          buildAutoTag(
                            accentColor: accentColor,
                            titleColor: titleColor,
                          ),
                          if (_isClient) ...[
                            const SizedBox(width: 8),
                            _buildCommunityToggle(
                              isDark: isDark,
                              titleColor: titleColor,
                              mutedColor: mutedColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // صورة + فيديو جنب بعض
                Row(
                  children: [
                    Expanded(
                      child: buildImagePicker(
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        iconBg: iconBg,
                        accentColor: accentColor,
                        titleColor: titleColor,
                        mutedColor: mutedColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildVideoPicker(
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        iconBg: iconBg,
                        accentColor: accentColor,
                        titleColor: titleColor,
                        mutedColor: mutedColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: cardBorder),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 6,
                    maxLines: 9,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: _isCommunityPost
                          ? l10n.describeProduct
                          : l10n.whatsOnYourMind,
                      hintStyle: TextStyle(color: mutedColor),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // Donation link field — charity accounts only.
                // The link is stored on `posts.donation_link` and
                // rendered as a "Donate now" button on every card
                // for this post (home feed + charities tab).
                if (_isCharity) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: cardBorder),
                    ),
                    child: TextField(
                      controller: donationLinkController,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      style: TextStyle(color: titleColor, fontSize: 15),
                      decoration: InputDecoration(
                        icon: Icon(
                          Icons.link_rounded,
                          color: accentColor,
                        ),
                        hintText: l10n.donationLinkHint,
                        hintStyle: TextStyle(color: mutedColor),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: TtsWrapper(
                      text: l10n.donationLinkNote,
                      child: Text(
                        l10n.donationLinkNote,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],

                if (createError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withOpacity(0.35)),
                    ),
                    child: Text(createError!, style: const TextStyle(color: Colors.red)),
                  ),
                ],

                const SizedBox(height: 22),

                TtsWrapper(
                  text: buttonLabel,
                  child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: buttonGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.6,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                buttonLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                ),
              ],
            ),
    );
  }
}