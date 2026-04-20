import 'dart:typed_data';
import 'dart:ui';

import 'package:ableplusproject/theme/App_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class tutorsSignup extends StatefulWidget {
  const tutorsSignup({super.key});

  @override
  State<tutorsSignup> createState() => _tutorsSignupState();
}

class _tutorsSignupState extends State<tutorsSignup> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  static const String _storageBucket = 'verification-files';

  bool _isSubmitting = false;

  Uint8List? _certificateBytes;
  Uint8List? _cvBytes;
  Uint8List? _idImageBytes;

  String? _certificateName;
  String? _cvName;
  String? _idImageName;

  Future<void> _pickFile({
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

  Future<String> _uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
    final path =
        '$folder/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

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

  Future<void> _submitTutorSignup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_certificateBytes == null) {
      _showSnackBar('Please upload your certificate proof.');
      return;
    }
    if (_cvBytes == null) {
      _showSnackBar('Please upload your CV or specialization file.');
      return;
    }
    if (_idImageBytes == null) {
      _showSnackBar('Please upload your ID image.');
      return;
    }

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('Your session was not found. Please sign up again.');
      return;
    }

    final routeExtra = GoRouterState.of(context).extra;
    final signupData = routeExtra is Map<String, dynamic> ? routeExtra : null;

    final fullName =
        (signupData?['full_name'] ??
                currentUser.userMetadata?['full_name'] ??
                '')
            .toString()
            .trim();

    final username =
        (signupData?['username'] ?? currentUser.userMetadata?['username'] ?? '')
            .toString()
            .trim();

    final email = (signupData?['email'] ?? currentUser.email ?? '')
        .toString()
        .trim();

    final password = (signupData?['password'] ?? '').toString();

    if (fullName.isEmpty || username.isEmpty || email.isEmpty) {
      _showSnackBar(
        'Missing account information. Please go back and complete signup again.',
      );
      return;
    }

    if (password.isEmpty) {
      _showSnackBar(
        'Password is missing for tutor table insert. Pass it from the general signup page.',
      );
      return;
    }
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'username': username},
    );

    setState(() => _isSubmitting = true);

    try {
      final certificateUrl = await _uploadFile(
        bytes: _certificateBytes!,
        fileName: _certificateName!,
        folder: 'tutors/certificate_prove',
      );

      final cvUrl = await _uploadFile(
        bytes: _cvBytes!,
        fileName: _cvName!,
        folder: 'tutors/cv',
      );

      final idImageUrl = await _uploadFile(
        bytes: _idImageBytes!,
        fileName: _idImageName!,
        folder: 'tutors/id_img',
      );

      String tutorId;

      final existingTutor = await supabase
          .from('tutors')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingTutor != null && existingTutor['id'] != null) {
        tutorId = existingTutor['id'] as String;

        await supabase
            .from('tutors')
            .update({
              'full_name': fullName,
              'username': username,
              'password': password,
            })
            .eq('id', tutorId);
      } else {
        final insertedTutor = await supabase
            .from('tutors')
            .insert({
              'full_name': fullName,
              'username': username,
              'email': email,
              'password': password,
            })
            .select('id')
            .single();

        tutorId = insertedTutor['id'] as String;
      }

      await supabase.from('media').insert([
        {
          'tutor_id': tutorId,
          'file_url': certificateUrl,
          'file_type': _certificateName!.split('.').last.toLowerCase(),
          'media_type': 'document',
          'category': 'certificate_prove',
        },
        {
          'tutor_id': tutorId,
          'file_url': cvUrl,
          'file_type': _cvName!.split('.').last.toLowerCase(),
          'media_type': 'document',
          'category': 'cv',
        },
        {
          'tutor_id': tutorId,
          'file_url': idImageUrl,
          'file_type': _idImageName!.split('.').last.toLowerCase(),
          'media_type': 'image',
          'category': 'id_img',
        },
      ]);

      if (!mounted) return;

      _showSnackBar('Tutor account submitted successfully for verification.');
      context.go('/login');
    } catch (e) {
      _showSnackBar('Failed to submit tutor signup: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 96),
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
                                  'Tutor Sign Up',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Additional verification is required for tutor accounts before approval.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: mutedColor,
                                    height: 1.5,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _UploadTile(
                                  icon: Icons.verified_outlined,
                                  title: 'Upload certificate proof',
                                  subtitle:
                                      _certificateName ??
                                      'PDF , Image or Document',
                                  accentColor: accentColor,
                                  cardColor: softCardColor,
                                  onTap: () => _pickFile(
                                    imagesOnly: false,
                                    onPicked: (bytes, name) {
                                      _certificateBytes = bytes;
                                      _certificateName = name;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
                                  _UploadTile(
                                    icon: Icons.description_outlined,
                                    title: 'Upload CV / specialization',
                                    subtitle:
                                        _cvName ?? 'PDF, image, or document',
                                    accentColor: accentColor,
                                    cardColor: softCardColor,
                                    onTap: () => _pickFile(
                                      imagesOnly: false,
                                      onPicked: (bytes, name) {
                                        _cvBytes = bytes;
                                        _cvName = name;
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
                                    onTap: () => _pickFile(
                                      imagesOnly: true,
                                      onPicked: (bytes, name) {
                                        _idImageBytes = bytes;
                                        _idImageName = name;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'These documents are required to verify your tutor account.',
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
                                          : _submitTutorSignup,
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
              Icon(Icons.chevron_right_rounded, color: accentColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}