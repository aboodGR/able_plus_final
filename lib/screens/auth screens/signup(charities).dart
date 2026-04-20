import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ableplusproject/theme/App_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CharitiesSignup extends StatefulWidget {
  const CharitiesSignup({super.key});

  @override
  State<CharitiesSignup> createState() => _CharitiesSignupState();
}

class _CharitiesSignupState extends State<CharitiesSignup> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  static const String _storageBucket = 'verification-files';

  final TextEditingController charityNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  bool _isSubmitting = false;

  Uint8List? _charityProofBytes;
  String? _charityProofFileName;

  Uint8List? _idImageBytes;
  String? _idImageName;

  @override
  void dispose() {
    charityNameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  String? _validateCharityName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Charity name is required';
    if (text.length < 3) return 'Enter a valid charity name';
    return null;
  }

  String? _validateLocation(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Location is required';
    if (text.length < 3) return 'Enter a valid location';
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickSingleFile({
    required bool imageOnly,
    required void Function(Uint8List bytes, String name) onPicked,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: imageOnly ? FileType.image : FileType.custom,
        allowedExtensions: imageOnly
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
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await supabase.storage
        .from(_storageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _contentTypeFromExtension(ext),
          ),
        );

    return supabase.storage.from(_storageBucket).getPublicUrl(path);
  }

  Future<void> _submitCharitySignup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_charityProofBytes == null) {
      _showSnackBar('Please upload charity proof.');
      return;
    }

    if (_idImageBytes == null) {
      _showSnackBar('Please upload your ID image.');
      return;
    }

    final extra = GoRouterState.of(context).extra;
    final signupData = extra is Map<String, dynamic> ? extra : null;

    final fullName = (signupData?['full_name'] ?? '').toString().trim();
    final username = (signupData?['username'] ?? '').toString().trim();
    final email = (signupData?['email'] ?? '').toString().trim();
    final password = (signupData?['password'] ?? '').toString();

    final charityName = charityNameController.text.trim();
    final location = locationController.text.trim();

    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showSnackBar('Missing signup data. Please start over.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': username, 'role': 'charity'},
      );

      final charityId = authResponse.user?.id;

      if (charityId == null) {
        throw Exception('User ID was not created.');
      }

      await supabase.from('charities').insert({
        'id': charityId,
        'full_name': fullName,
        'username': username,
        'email': email,
        'charity_name': charityName,
        'location': location,
      });

      final charityProofUrl = await _uploadFile(
        bytes: _charityProofBytes!,
        fileName: _charityProofFileName!,
        folder: 'charities/charity_proof',
      );

      final idImageUrl = await _uploadFile(
        bytes: _idImageBytes!,
        fileName: _idImageName!,
        folder: 'charities/id_img',
      );

      await supabase.from('charity_verification').insert([
        {
          'charity_id': charityId,
          'file_url': charityProofUrl,
          'file_type': _charityProofFileName!.split('.').last.toLowerCase(),
          'media_type': 'document',
          'category': 'charity_proof',
        },
        {
          'charity_id': charityId,
          'file_url': idImageUrl,
          'file_type': _idImageName!.split('.').last.toLowerCase(),
          'media_type': 'image',
          'category': 'id_image',
        },
      ]);

      if (!mounted) return;

      _showSnackBar(
        'Charity account submitted successfully. Please verify your email.',
      );
      context.go('/login');
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Failed to submit charity signup: $e');
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
        : Colors.black.withOpacity(0.08);

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
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 68),
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
                                    'Charity Sign Up',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Additional verification is required for charity accounts before approval.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: mutedColor,
                                      height: 1.5,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _AbleInput(
                                    controller: charityNameController,
                                    hint: 'Charity name',
                                    icon: Icons.volunteer_activism_outlined,
                                    validator: _validateCharityName,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 14),
                                  _AbleInput(
                                    controller: locationController,
                                    hint: 'Charity location',
                                    icon: Icons.location_on_outlined,
                                    validator: _validateLocation,
                                    textInputAction: TextInputAction.done,
                                  ),
                                  const SizedBox(height: 14),
                                  _UploadTile(
                                    icon: Icons.verified_user_outlined,
                                    title: 'Upload charity proof',
                                    subtitle:
                                        _charityProofFileName ??
                                        'PDF, image, or document',
                                    accentColor: accentColor,
                                    cardColor: softCardColor,
                                    onTap: () => _pickSingleFile(
                                      imageOnly: false,
                                      onPicked: (bytes, name) {
                                        _charityProofBytes = bytes;
                                        _charityProofFileName = name;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _UploadTile(
                                    icon: Icons.badge_outlined,
                                    title: 'Upload ID image',
                                    subtitle:
                                        _idImageName ?? 'JPG, JPEG, or PNG',
                                    accentColor: accentColor,
                                    cardColor: softCardColor,
                                    onTap: () => _pickSingleFile(
                                      imageOnly: true,
                                      onPicked: (bytes, name) {
                                        _idImageBytes = bytes;
                                        _idImageName = name;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'These documents are required to verify your charity account.',
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
                                            color: const Color(
                                              0xFF0B82D2,
                                            ).withOpacity(0.22),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _submitCharitySignup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
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

class _AbleInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const _AbleInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.validator,
    required this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: textInputAction,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback onTap;

  const _UploadTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.upload_file, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}
