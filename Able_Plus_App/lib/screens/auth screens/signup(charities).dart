import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/theme/App_theme.dart';
import 'package:ableplusproject/widgets/AuthLanguageToggle.dart';
import 'package:ableplusproject/widgets/AuthTtsToggle.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:ableplusproject/widgets/LocationPickerButton.dart';
import 'package:ableplusproject/services/location_service.dart';
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

  bool _isSubmitting = false;

  LocationResult? _capturedLocation;

  Uint8List? _charityProofBytes;
  String? _charityProofFileName;

  Uint8List? _idImageBytes;
  String? _idImageName;

  @override
  void dispose() {
    charityNameController.dispose();
    super.dispose();
  }

  String? _validateCharityName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.charityNameRequired;
    if (text.length < 3) return l10n.enterValidCharityName;
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
    final l10n = AppLocalizations.of(context)!;
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
        _showSnackBar(l10n.couldNotReadFile);
        return;
      }

      onPicked(bytes, file.name);
      setState(() {});
    } catch (e) {
      _showSnackBar('${l10n.failedToPickFile}: $e');
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

  Future<void> _insertPendingCharityRequest({
    required String charityId,
    required String fullName,
    required String username,
    required String email,
    required String charityName,
    required String location,
    required double latitude,
    required double longitude,
    required String charityProofUrl,
    required String idImageUrl,
  }) async {
    // Calls a SECURITY DEFINER Postgres function which bypasses RLS while
    // still verifying that charityId belongs to a real auth.users row.
    await supabase.rpc(
      'submit_pending_charity_request',
      params: {
        'p_id': charityId,
        'p_full_name': fullName,
        'p_username': username,
        'p_email': email,
        'p_charity_name': charityName,
        'p_location': location,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_charity_prove_url': charityProofUrl,
        'p_id_img_url': idImageUrl,
      },
    );
  }

  Future<void> _submitCharitySignup() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_capturedLocation == null) {
      _showSnackBar(l10n.pleaseShareLocation);
      return;
    }

    if (_charityProofBytes == null) {
      _showSnackBar(l10n.pleaseUploadCharityProof);
      return;
    }

    if (_idImageBytes == null) {
      _showSnackBar(l10n.pleaseUploadIdImage);
      return;
    }

    final extra = GoRouterState.of(context).extra;
    final signupData = extra is Map<String, dynamic> ? extra : null;

    final fullName = (signupData?['fullName'] ?? signupData?['full_name'] ?? '')
        .toString()
        .trim();

    final username = (signupData?['username'] ?? '').toString().trim();

    final email = (signupData?['email'] ?? '').toString().trim().toLowerCase();

    final password = (signupData?['password'] ?? '').toString();

    final charityName = charityNameController.text.trim();

    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showSnackBar(l10n.missingSignupDataStartOver);
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

      await _insertPendingCharityRequest(
        charityId: charityId,
        fullName: fullName,
        username: username,
        email: email,
        charityName: charityName,
        location: (_capturedLocation!.address != null && _capturedLocation!.address!.isNotEmpty)
    ? _capturedLocation!.address!
    : '${_capturedLocation!.latitude}, ${_capturedLocation!.longitude}',
        latitude: _capturedLocation!.latitude,
        longitude: _capturedLocation!.longitude,
        charityProofUrl: charityProofUrl,
        idImageUrl: idImageUrl,
      );

      if (!mounted) return;

      _showSnackBar(l10n.charitySubmittedVerifyEmail);
      context.go('/login');
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('${l10n.failedToSubmitCharity}: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                                  TtsWrapper(
                                    text: '${l10n.charitySignUp}. ${l10n.charityVerificationNotice}',
                                    child: Text(
                                      l10n.charitySignUp,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.charityVerificationNotice,
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
                                    hint: l10n.charityNameLabel,
                                    icon: Icons.volunteer_activism_outlined,
                                    validator: _validateCharityName,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 14),
                                  LocationPickerButton(
                                    showPublicNotice: true,
                                    hint: l10n.useCurrentLocation,
                                    onLocationPicked: (result) {
                                      setState(() {
                                        _capturedLocation = result;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _UploadTile(
                                    icon: Icons.verified_user_outlined,
                                    title: l10n.uploadCharityProof,
                                    subtitle:
                                        _charityProofFileName ??
                                        l10n.fileFormatsHint,
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
                                    title: l10n.uploadIdImage,
                                    subtitle:
                                        _idImageName ?? l10n.idImageFormats,
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
                                  TtsWrapper(
                                    text: l10n.charityDocumentsNotice,
                                    child: Text(
                                      l10n.charityDocumentsNotice,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: mutedColor,
                                        height: 1.5,
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
                                  TtsWrapper(
                                    text: l10n.alreadyHaveAccount,
                                    child: Text(
                                      l10n.alreadyHaveAccount,
                                      style: TextStyle(color: mutedColor),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TtsWrapper(
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
    return TtsWrapper(
      text: '$title. $subtitle',
      child: Material(
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
      ),
    );
  }
}