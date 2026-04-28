import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';

class _AccountInfo {
  final String table;
  final String postColumn;
  final String id;

  const _AccountInfo({
    required this.table,
    required this.postColumn,
    required this.id,
  });
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final controller = TextEditingController();
  final picker = ImagePicker();

  File? selectedImage;
  Uint8List? selectedImageBytes;
  XFile? pickedImage;

  String type = 'user-to-user';
  bool isLoading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);

                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );

                    if (image != null) {
                      await setPickedImage(image);
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);

                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );

                  if (image != null) {
                    await setPickedImage(image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_AccountInfo> _loadCurrentAccount() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No user is logged in. Please login first.');
    }

    final userId = user.id;

    final tables = [
      const _AccountInfo(
        table: 'clients',
        postColumn: 'client_id',
        id: '',
      ),
      const _AccountInfo(
        table: 'tutors',
        postColumn: 'tutor_id',
        id: '',
      ),
      const _AccountInfo(
        table: 'businesses',
        postColumn: 'business_id',
        id: '',
      ),
      const _AccountInfo(
        table: 'charities',
        postColumn: 'charity_id',
        id: '',
      ),
    ];

    for (final info in tables) {
      final row = await supabase
          .from(info.table)
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (row != null) {
        return _AccountInfo(
          table: info.table,
          postColumn: info.postColumn,
          id: userId,
        );
      }
    }

    throw Exception('Account not found in database. Please login again.');
  }

  Future<String?> uploadPostImage() async {
    if (pickedImage == null) return null;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No user is logged in. Please login first.');
    }

    final fileExt = pickedImage!.path.split('.').last;
    final fileName =
        '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'posts/$fileName';

    if (kIsWeb) {
      final bytes = await pickedImage!.readAsBytes();

      await supabase.storage.from('post-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } else {
      final file = File(pickedImage!.path);

      await supabase.storage.from('post-images').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
    }

    return supabase.storage.from('post-images').getPublicUrl(filePath);
  }

  Future<void> createPost() async {
    final content = controller.text.trim();

    if (content.isEmpty && pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or choose an image')),
      );
      return;
    }

    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final account = await _loadCurrentAccount();

      final imageUrl = await uploadPostImage();

      await supabase.from('posts').insert({
        account.postColumn: account.id,
        'content': content.isEmpty ? null : content,
        'image_url': imageUrl,
        'type': type,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);
    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;
    final accentColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.55);

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

    return AbleScaffold(
      title: 'Create Post',
      currentIndex: 2,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            'Share something with the community',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload media, add a description, and choose the post type.',
            style: TextStyle(color: mutedColor),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: pickImage,
            child: Card(
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder),
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
                              Icons.cloud_upload_outlined,
                              size: 32,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upload photo',
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            kIsWeb
                                ? 'Tap to choose from gallery'
                                : 'Tap to use camera or gallery',
                            style: TextStyle(color: mutedColor, fontSize: 13),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: buildSelectedImage(),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 7,
            style: TextStyle(color: titleColor, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Write a description...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: type,
            dropdownColor: isDark ? const Color(0xFF1A2740) : Colors.white,
            decoration: const InputDecoration(hintText: 'Post type'),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'user-to-user', child: Text('Community')),
              DropdownMenuItem(value: 'charity', child: Text('Charity')),
              DropdownMenuItem(value: 'business', child: Text('Business')),
              DropdownMenuItem(value: 'educational', child: Text('Educational')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => type = value);
            },
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: buttonGradient,
              borderRadius: BorderRadius.circular(30),
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
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Add post',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}