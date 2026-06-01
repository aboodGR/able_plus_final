import 'dart:typed_data';
import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/services/location_service.dart';
import 'package:ableplusproject/widgets/AuthLanguageToggle.dart';
import 'package:ableplusproject/widgets/AuthTtsToggle.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:ableplusproject/widgets/LocationPickerButton.dart';
import 'package:ableplusproject/widgets/SubjectChipsInput.dart';
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

  final TextEditingController _bioController = TextEditingController();

  LocationResult? _capturedLocation;
  List<String> _subjects = [];

  bool _isSubmitting = false;

  Uint8List? _certificateBytes;
  Uint8List? _cvBytes;
  Uint8List? _idImageBytes;

  String? _certificateName;
  String? _cvName;
  String? _idImageName;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  String? _validateBio(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';

    if (text.isEmpty) return l10n.bioRequired;
    if (text.length < 20) return l10n.bioMinChars;

    return null;
  }

  Future<void> _pickFile({
    required bool imagesOnly,
    required void Function(Uint8List bytes, String name) onPicked,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: imagesOnly
            ? ['jpg', 'jpeg', 'png', 'webp', 'avif', 'heic', 'heif']
            : [
                'pdf',
                'jpg',
                'jpeg',
                'png',
                'webp',
                'avif',
                'heic',
                'heif',
                'doc',
                'docx',
              ],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        _showSnackBar(l10n.couldNotReadFile);
        return;
      }

      onPicked(bytes, file.name);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showSnackBar('${l10n.failedToPickFile}: $e');
    }
  }

  String _safeStorageFileName(String fileName) {
    final originalName = fileName.trim();

    final dotIndex = originalName.lastIndexOf('.');
    final rawExt = dotIndex == -1 ? 'bin' : originalName.substring(dotIndex + 1);

    final ext = rawExt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final rawName = dotIndex == -1
        ? originalName
        : originalName.substring(0, dotIndex);

    final safeBaseName = rawName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final finalBaseName = safeBaseName.isEmpty ? 'file' : safeBaseName;
    final finalExt = ext.isEmpty ? 'bin' : ext;

    return '$finalBaseName.$finalExt';
  }

  Future<String> _uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required String userId,
  }) async {
    final safeFileName = _safeStorageFileName(fileName);
    final ext = safeFileName.split('.').last.toLowerCase();

    final path =
        '$folder/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

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

  String _contentTypeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'avif':
        return 'image/avif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _insertPendingTutorRequest({
    required String tutorId,
    required String fullName,
    required String username,
    required String email,
    required String bio,
    required List<String> subjects,
    required LocationResult location,
    required String certificateUrl,
    required String cvUrl,
    required String idImageUrl,
  }) async {
    final cleanSubjects = subjects
        .map((subject) => subject.trim())
        .where((subject) => subject.isNotEmpty)
        .toList();

    if (cleanSubjects.isEmpty) {
      throw Exception('Please add at least one subject.');
    }

    await supabase.rpc(
      'submit_pending_tutor_request',
      params: {
        'p_id': tutorId,
        'p_full_name': fullName.trim(),
        'p_username': username.trim(),
        'p_email': email.trim().toLowerCase(),
        'p_certificate_url': certificateUrl,
        'p_cv_url': cvUrl,
        'p_id_img_url': idImageUrl,
        'p_bio': bio.trim(),
        'p_subject': cleanSubjects,

        // لا نخزن اسم المنطقة ولا الإحداثيات كنص في location
        // التطبيق سيعرض المحافظة لاحقًا من latitude و longitude فقط
        'p_location': null,

        // نخزن الإحداثيات فقط
        'p_latitude': location.latitude,
        'p_longitude': location.longitude,
      },
    );
  }

  Future<void> _submitTutorSignup() async {
    final l10n = AppLocalizations.of(context)!;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_capturedLocation == null) {
      _showSnackBar(l10n.pleaseShareLocation);
      return;
    }

    if (_subjects.isEmpty) {
      _showSnackBar(l10n.pleaseAddSubject);
      return;
    }

    if (_certificateBytes == null || _certificateName == null) {
      _showSnackBar(l10n.pleaseUploadCertificate);
      return;
    }

    if (_cvBytes == null || _cvName == null) {
      _showSnackBar(l10n.pleaseUploadCv);
      return;
    }

    if (_idImageBytes == null || _idImageName == null) {
      _showSnackBar(l10n.pleaseUploadIdImage);
      return;
    }

    final routeExtra = GoRouterState.of(context).extra;
    final signupData = routeExtra is Map<String, dynamic> ? routeExtra : null;

    final fullName = (signupData?['fullName'] ?? signupData?['full_name'] ?? '')
        .toString()
        .trim();

    final username = (signupData?['username'] ?? '').toString().trim();

    final email = (signupData?['email'] ?? '').toString().trim().toLowerCase();

    final password = (signupData?['password'] ?? '').toString();

    final bio = _bioController.text.trim();

    if (fullName.isEmpty || username.isEmpty || email.isEmpty) {
      _showSnackBar(l10n.missingAccountInfo);
      return;
    }

    if (password.isEmpty) {
      _showSnackBar(l10n.passwordMissingGoBack);
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
          'role': 'tutor',
        },
      );

      final tutorId = authResponse.user?.id;

      if (tutorId == null) {
        throw Exception('Tutor auth account was not created.');
      }

      final certificateUrl = await _uploadFile(
        bytes: _certificateBytes!,
        fileName: _certificateName!,
        folder: 'tutors/certificate_prove',
        userId: tutorId,
      );

      final cvUrl = await _uploadFile(
        bytes: _cvBytes!,
        fileName: _cvName!,
        folder: 'tutors/cv',
        userId: tutorId,
      );

      final idImageUrl = await _uploadFile(
        bytes: _idImageBytes!,
        fileName: _idImageName!,
        folder: 'tutors/id_img',
        userId: tutorId,
      );

      await _insertPendingTutorRequest(
        tutorId: tutorId,
        fullName: fullName,
        username: username,
        email: email,
        bio: bio,
        subjects: _subjects,
        location: _capturedLocation!,
        certificateUrl: certificateUrl,
        cvUrl: cvUrl,
        idImageUrl: idImageUrl,
      );

      if (!mounted) return;

      _showSnackBar(l10n.tutorSubmittedForVerification);
      context.go('/login');
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('${l10n.failedToSubmitTutor}: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.72);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.55);

    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;

    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    final accentColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: TtsWrapper(
                                      text:
                                          '${l10n.tutorSignUp}. ${l10n.tutorVerificationNotice}',
                                      child: Text(
                                        l10n.tutorSignUp,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: titleColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                      l10n.tutorVerificationNotice,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: mutedColor,
                                        height: 1.5,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  TtsWrapper(
                                    text: l10n.yourBio,
                                    child: Text(
                                      l10n.yourBio,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _bioController,
                                    validator: _validateBio,
                                    maxLines: 4,
                                    minLines: 3,
                                    maxLength: 400,
                                    textInputAction: TextInputAction.newline,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: l10n.bioHint,
                                      hintStyle: TextStyle(
                                        color: mutedColor,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                      filled: true,
                                      fillColor: softCardColor,
                                      contentPadding: const EdgeInsets.all(14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TtsWrapper(
                                    text: l10n.subjectsYouTeach,
                                    child: Text(
                                      l10n.subjectsYouTeach,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SubjectChipsInput(
                                    onChanged: (list) {
                                      setState(() {
                                        _subjects = list;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TtsWrapper(
                                    text: l10n.yourLocation,
                                    child: Text(
                                      l10n.yourLocation,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  LocationPickerButton(
                                    showPublicNotice: false,
                                    hint: l10n.useCurrentLocation,
                                    onLocationPicked: (result) {
                                      setState(() {
                                        _capturedLocation = result;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  TtsWrapper(
                                    text: l10n.locationPrivateNote,
                                    child: Text(
                                      l10n.locationPrivateNote,
                                      style: TextStyle(
                                        color: mutedColor,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _UploadTile(
                                    icon: Icons.verified_outlined,
                                    title: l10n.uploadCertificateProof,
                                    subtitle: _certificateName ??
                                        l10n.certificateFormatsHint,
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
                                    title: l10n.uploadCvSpecialization,
                                    subtitle: _cvName ?? l10n.fileFormatsHint,
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
                                    title: l10n.uploadIdImage,
                                    subtitle:
                                        _idImageName ?? l10n.idImageFormats,
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
                                  Center(
                                    child: TtsWrapper(
                                      text: l10n.tutorDocumentsNotice,
                                      child: Text(
                                        l10n.tutorDocumentsNotice,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: mutedColor,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  TtsWrapper(
                                    text: l10n.submitForApproval,
                                    child: Container(
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
                                            : _submitTutorSignup,
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
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                l10n.submitForApproval,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Center(
                                    child: TtsWrapper(
                                      text: l10n.alreadyHaveAccount,
                                      child: Text(
                                        l10n.alreadyHaveAccount,
                                        style: TextStyle(color: mutedColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: TtsWrapper(
                                      text: l10n.login,
                                      child: TextButton(
                                        onPressed: () => context.go('/login'),
                                        child: Text(
                                          l10n.login,
                                          style: TextStyle(
                                            color: accentColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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
          PositionedDirectional(
            top: 8,
            end: 8,
            child: SafeArea(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  AuthTtsToggle(),
                  SizedBox(width: 8),
                  AuthLanguageToggle(),
                ],
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
    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    return TtsWrapper(
      text: '$title. $subtitle',
      child: Material(
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
                Transform.flip(
                  flipX: Directionality.of(context) == TextDirection.rtl,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: accentColor,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}