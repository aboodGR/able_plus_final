import 'dart:typed_data';
import 'dart:ui';

import 'package:ableplusproject/theme/App_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class businessSignup extends StatefulWidget {
  const businessSignup({super.key});

  @override
  State<businessSignup> createState() => _businessSignupState();
}

class _businessSignupState extends State<businessSignup> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  static const String _storageBucket = 'verification-files';

  final TextEditingController locationController = TextEditingController();

  bool _isSubmitting = false;

  List<Uint8List> _businessImageBytesList = [];
  List<String> _businessImageNamesList = [];

  Uint8List? _commercialRegisterBytes;
  String? _commercialRegisterName;

  Uint8List? _idImageBytes;
  String? _idImageName;

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  String? _validateLocation(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Location is required';
    if (text.length < 3) return 'Enter a valid location';
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickBusinessImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.image,
      );

      if (result == null || result.files.isEmpty) return;

      if (result.files.length < 3 || result.files.length > 5) {
        _showSnackBar('Please select between 3 and 5 business photos.');
        return;
      }

      final bytesList = <Uint8List>[];
      final namesList = <String>[];

      for (final file in result.files) {
        if (file.bytes == null) {
          _showSnackBar('One of the selected images could not be read.');
          return;
        }
        bytesList.add(file.bytes!);
        namesList.add(file.name);
      }

      setState(() {
        _businessImageBytesList = bytesList;
        _businessImageNamesList = namesList;
      });
    } catch (e) {
      _showSnackBar('Failed to pick business photos: $e');
    }
  }

  Future<void> _pickSingleFile({
    required bool imagesOnly,
    required void Function(Uint8List bytes, String name) onPicked,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: imagesOnly ? FileType.image : FileType.custom,
        allowedExtensions: imagesOnly
            ? null
            : ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        _showSnackBar('Could not read the selected file.');
        return;
      }

      onPicked(bytes, file.name);
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to pick file: $e');
    }
  }

  String _contentTypeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> _uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
    final path =
        '$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await supabase.storage.from(_storageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _contentTypeFromExtension(ext),
          ),
        );

    return supabase.storage.from(_storageBucket).getPublicUrl(path);
  }

  Future<void> _submitBusinessSignup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_businessImageBytesList.length < 3 || _businessImageBytesList.length > 5) {
      _showSnackBar('Please upload 3 to 5 business photos.');
      return;
    }

    if (_commercialRegisterBytes == null) {
      _showSnackBar('Please upload the commercial register.');
      return;
    }

    if (_idImageBytes == null) {
      _showSnackBar('Please upload the ID image.');
      return;
    }

    final extra = GoRouterState.of(context).extra;
    final signupData = extra is Map<String, dynamic> ? extra : null;

    final fullName = (signupData?['full_name'] ?? '').toString().trim();
    final username = (signupData?['username'] ?? '').toString().trim();
    final email = (signupData?['email'] ?? '').toString().trim();
    final password = (signupData?['password'] ?? '').toString();
    final location = locationController.text.trim();

    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showSnackBar('Missing signup information. Please go back and sign up again.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'username': username,
          'role': 'business',
        },
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        _showSnackBar('Could not create business account.');
        return;
      }

      final businessId = authUser.id;

      await supabase.from('businesses').insert({
        'id': businessId,
        'full_name': fullName,
        'username': username,
        'email': email,
        'password': password,
        'location': location,
      });

      final mediaRows = <Map<String, dynamic>>[];

      for (int i = 0; i < _businessImageBytesList.length; i++) {
        final imageUrl = await _uploadFile(
          bytes: _businessImageBytesList[i],
          fileName: _businessImageNamesList[i],
          folder: 'businesses/business_img',
        );

        mediaRows.add({
          'business_id': businessId,
          'file_url': imageUrl,
          'file_type': _businessImageNamesList[i].split('.').last.toLowerCase(),
          'media_type': 'image',
          'category': 'business_img',
        });
      }

      final commercialRegisterUrl = await _uploadFile(
        bytes: _commercialRegisterBytes!,
        fileName: _commercialRegisterName!,
        folder: 'businesses/commercial_register',
      );

      mediaRows.add({
        'business_id': businessId,
        'file_url': commercialRegisterUrl,
        'file_type': _commercialRegisterName!.split('.').last.toLowerCase(),
        'media_type': 'document',
        'category': 'commercial_register',
      });

      final idImageUrl = await _uploadFile(
        bytes: _idImageBytes!,
        fileName: _idImageName!,
        folder: 'businesses/id_img',
      );

      mediaRows.add({
        'business_id': businessId,
        'file_url': idImageUrl,
        'file_type': _idImageName!.split('.').last.toLowerCase(),
        'media_type': 'image',
        'category': 'id_img',
      });

      await supabase.from('media').insert(mediaRows);

      if (!mounted) return;

      _showSnackBar(
        'Business account submitted successfully. Please verify your email.',
      );
      context.go('/login');
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Failed to submit business signup: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.72);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.55);

    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;

    final mutedColor = isDark
        ? AbleColors.darkTextMuted
        : AbleColors.lightTextMuted;

    final accentColor = isDark
        ? AbleColors.darkSecondary
        : AbleColors.lightPrimaryDark;

    final softCardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFF3F8FC).withOpacity(0.88);

    final buttonGradient = isDark
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0B2C66), Color(0xFF1551A8), Color(0xFF6ED4E6)],
          )
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF2D65B2), Color(0xFF4B96D9), Color(0xFF77D5E7)],
          );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AbleTheme.backgroundAsset(context),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.10)
                  : Colors.white.withOpacity(0.03),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Image.asset(
                          AbleTheme.logoAsset,
                          fit: BoxFit.contain,
                          height: 120,
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.35)
                                        : const Color(0x220AC4E0),
                                    blurRadius: 26,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Business Sign Up',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Additional verification is required for business accounts before approval.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: mutedColor,
                                      height: 1.5,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _AbleInput(
                                    controller: locationController,
                                    hint: 'Business location',
                                    icon: Icons.location_on_outlined,
                                    validator: _validateLocation,
                                    textInputAction: TextInputAction.done,
                                  ),
                                  const SizedBox(height: 14),
                                  _UploadTile(
                                    icon: Icons.photo_library_outlined,
                                    title: 'Upload 3-5 business photos',
                                    subtitle: _businessImageNamesList.isEmpty
                                        ? 'Accessibility photos of the business'
                                        : '${_businessImageNamesList.length} photos selected',
                                    accentColor: accentColor,
                                    cardColor: softCardColor,
                                    onTap: _pickBusinessImages,
                                  ),
                                  if (_businessImageNamesList.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _businessImageNamesList.join('\n'),
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  _UploadTile(
                                    icon: Icons.description_outlined,
                                    title: 'Upload commercial register',
                                    subtitle: _commercialRegisterName ??
                                        'PDF, image, or document',
                                    accentColor: accentColor,
                                    cardColor: softCardColor,
                                    onTap: () => _pickSingleFile(
                                      imagesOnly: false,
                                      onPicked: (bytes, name) {
                                        _commercialRegisterBytes = bytes;
                                        _commercialRegisterName = name;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _UploadTile(
                                    icon: Icons.badge_outlined,
                                    title: 'Upload ID image',
                                    subtitle: _idImageName ?? 'JPG, JPEG, or PNG',
                                    accentColor: accentColor,
                                    cardColor: softCardColor,
                                    onTap: () => _pickSingleFile(
                                      imagesOnly: true,
                                      onPicked: (bytes, name) {
                                        _idImageBytes = bytes;
                                        _idImageName = name;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'These documents are required to verify your business account.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: mutedColor,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Container(
                                    width: double.infinity,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: buttonGradient,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        if (isDark)
                                          BoxShadow(
                                            color: const Color(0xFF0B82D2)
                                                .withOpacity(0.22),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _submitBusinessSignup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Submit for Approval',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Already have an account?',
                                    style: TextStyle(color: mutedColor),
                                  ),
                                  const SizedBox(height: 4),
                                  TextButton(
                                    onPressed: () => context.go('/login'),
                                    child: Text(
                                      'Log in',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.cardColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final mutedColor = isDark
        ? AbleColors.darkTextMuted
        : AbleColors.lightTextMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
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
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
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
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbleInput extends StatelessWidget {
  const _AbleInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AbleColors.darkTextMuted
        : AbleColors.lightTextMuted;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        color: isDark ? AbleColors.darkText : AbleColors.lightText,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: mutedColor, size: 22),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }
}