import 'dart:ui';
import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/services/location_service.dart';
import 'package:ableplusproject/theme/App_theme.dart';
import 'package:ableplusproject/widgets/AuthLanguageToggle.dart';
import 'package:ableplusproject/widgets/AuthTtsToggle.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeneralSignup extends StatefulWidget {
  final String selectedUserType;

  const GeneralSignup({super.key, required this.selectedUserType});

  @override
  State<GeneralSignup> createState() => _GeneralSignupState();
}

class _GeneralSignupState extends State<GeneralSignup> {
  final _formkey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isloading = false;

  Future<void> _handleContinue(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (!_formkey.currentState!.validate()) return;

    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final userType = widget.selectedUserType.trim().toLowerCase();

    final signupPayload = {
      'fullName': fullName,
      'username': username,
      'email': email,
      'password': password,
    };

    if (userType == 'user') {
      // NEW: capture location BEFORE creating the account (signup blocked if denied)
      setState(() => isloading = true);

      final location = await LocationService.requestAndGetLocation(
        context,
        showPublicNotice: false, // private — clients aren't on the map
      );

      if (!mounted) {
        setState(() => isloading = false);
        return;
      }

      if (location == null) {
        setState(() => isloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationRequiredForAccount),
          ),
        );
        return;
      }

      try {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'https://mohamad-my.github.io/able-plus-web/',
          data: {'full_name': fullName, 'username': username, 'role': 'client'},
        );

        if (!mounted) return;

        if (response.user == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.signupFailed)));
          return;
        }

        final clientId = response.user!.id;

        // NEW: insert lat/long with the rest of the client row
        await supabase.rpc(
          'submit_client_signup',
          params: {
            'p_id': clientId,
            'p_full_name': fullName,
            'p_username': username,
            'p_email': email,
            'p_latitude': location.latitude,
            'p_longitude': location.longitude,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountCreatedVerifyEmail),
          ),
        );

        context.push('/login');
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.errorColon}: $e')));
      } finally {
        if (mounted) setState(() => isloading = false);
      }
      return;
    }

    // Non-client paths — unchanged, location is captured inside their screens.
    setState(() => isloading = true);

    try {
      if (userType == 'business' || userType == 'businesses') {
        context.push('/businesses-signup', extra: signupPayload);
      } else if (userType == 'charity') {
        context.push('/charity-signup', extra: signupPayload);
      } else if (userType == 'tutor') {
        context.push('/tutor-signup', extra: signupPayload);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.unknownAccountType(userType))),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.errorColon}: $e')));
    } finally {
      if (mounted) setState(() => isloading = false);
    }
  }

  String? _validateFullName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.fullNameRequired;
    if (text.length < 3) return l10n.fullNameMin3;

    final nameRegex = RegExp(r"^[a-zA-Z\u0600-\u06FF\s]+$");
    if (!nameRegex.hasMatch(text)) {
      return l10n.fullNameLettersOnly;
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';

    if (text.isEmpty) return l10n.usernameRequired;
    if (text.length < 3) return l10n.usernameMin3;
    if (text.length > 20) return l10n.usernameMax20;

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(text)) {
      return l10n.usernameAllowedChars;
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';

    if (text.isEmpty) return l10n.emailRequired;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(text)) {
      return l10n.enterValidEmail;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value ?? '';

    if (text.isEmpty) return l10n.passwordRequired;
    if (text.length < 8) return l10n.passwordMin8;
    if (!RegExp(r'[A-Z]').hasMatch(text)) {
      return l10n.passwordNeedsUppercase;
    }
    if (!RegExp(r'[a-z]').hasMatch(text)) {
      return l10n.passwordNeedsLowercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(text)) {
      return l10n.passwordNeedsNumber;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value ?? '';

    if (text.isEmpty) return l10n.confirmPasswordRequired;
    if (text != passwordController.text) return l10n.passwordsDoNotMatch;

    return null;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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

    final mutedColor = isDark
        ? AbleColors.darkTextMuted
        : AbleColors.lightTextMuted;

    final accentColor = isDark
        ? AbleColors.darkSecondary
        : AbleColors.lightPrimaryDark;

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
                    key: _formkey,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Image.asset(AbleTheme.logoAsset, fit: BoxFit.contain),
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
                                  TtsWrapper(
                                    text: '${l10n.createYourAccount}. ${l10n.signupRolesSubtitle}',
                                    child: Text(
                                      l10n.createYourAccount,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.signupRolesSubtitle,
                                    style: TextStyle(
                                      color: mutedColor,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _AbleInput(
                                    controller: fullNameController,
                                    hint: l10n.fullName,
                                    icon: Icons.badge_outlined,
                                    validator: _validateFullName,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  _AbleInput(
                                    controller: usernameController,
                                    hint: l10n.username,
                                    icon: Icons.person_outline_rounded,
                                    validator: _validateUsername,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  _AbleInput(
                                    controller: emailController,
                                    hint: l10n.email,
                                    icon: Icons.email_outlined,
                                    validator: _validateEmail,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  _AbleInput(
                                    controller: passwordController,
                                    hint: l10n.password,
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: obscurePassword,
                                    validator: _validatePassword,
                                    textInputAction: TextInputAction.next,
                                    suffix: IconButton(
                                      onPressed: () => setState(() {
                                        obscurePassword = !obscurePassword;
                                      }),
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _AbleInput(
                                    controller: confirmPasswordController,
                                    hint: l10n.confirmPassword,
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: obscureConfirmPassword,
                                    validator: _validateConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    suffix: IconButton(
                                      onPressed: () => setState(() {
                                        obscureConfirmPassword =
                                            !obscureConfirmPassword;
                                      }),
                                      icon: Icon(
                                        obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : const Color(
                                              0xFFF3F8FC,
                                            ).withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : const Color(0xFFD9E8F3),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 18,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TtsWrapper(
                                            text: widget.selectedUserType == 'user'
                                                ? l10n.locationNoticeUser
                                                : l10n.verificationNoticeOther,
                                            child: Text(
                                              widget.selectedUserType == 'user'
                                                  ? l10n.locationNoticeUser
                                                  : l10n.verificationNoticeOther,
                                              style: TextStyle(
                                                color: mutedColor,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TtsWrapper(
                                    text: widget.selectedUserType == 'user'
                                        ? l10n.createAccount
                                        : l10n.continueToVerification,
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
                                      onPressed: isloading
                                          ? null
                                          : () => _handleContinue(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child: isloading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              widget.selectedUserType == 'user'
                                                  ? l10n.createAccount
                                                  : l10n.continueToVerification,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: TtsWrapper(
                                      text: '${l10n.alreadyHaveAccount} ${l10n.login}',
                                      child: GestureDetector(
                                      onTap: () => context.push('/login'),
                                      child: Text.rich(
                                        TextSpan(
                                          text: '${l10n.alreadyHaveAccount} ',
                                          style: TextStyle(color: mutedColor),
                                          children: [
                                            TextSpan(
                                              text: l10n.login,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: accentColor,
                                              ),
                                            ),
                                          ],
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

class _AbleInput extends StatelessWidget {
  const _AbleInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
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
      obscureText: obscureText,
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
        suffixIcon: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }
}