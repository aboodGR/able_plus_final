import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/theme/App_theme.dart';
import 'package:ableplusproject/widgets/AuthLanguageToggle.dart';
import 'package:ableplusproject/widgets/AuthTtsToggle.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final password = value?.trim() ?? '';

    if (password.isEmpty) return l10n.pleaseEnterNewPassword;
    if (password.length < 8) return l10n.passwordMin8;
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return l10n.passwordNeedsUppercase;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return l10n.passwordNeedsLowercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return l10n.passwordNeedsNumber;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final confirmPassword = value?.trim() ?? '';
    final password = _passwordController.text.trim();

    if (confirmPassword.isEmpty) return l10n.pleaseConfirmPassword;
    if (confirmPassword != password) return l10n.passwordsDoNotMatch;

    return null;
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final session = supabase.auth.currentSession;

      if (session == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sessionExpired)),
        );

        context.push('/login');
        return;
      }

      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      if (!mounted) return;

      await supabase.auth.signOut(scope: SignOutScope.local);

      if (!mounted) return;

      context.push('/login');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordUpdatedSuccessfully)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      String message = e.message;
      final lower = e.message.toLowerCase();

      if (lower.contains('session')) {
        message = l10n.sessionExpired;
      } else if (lower.contains('same password')) {
        message = l10n.chooseDifferentPassword;
      } else if (lower.contains('password')) {
        message = l10n.enterStrongerPassword;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.failedToResetPassword}: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);
    final textPrimary = AbleTheme.textPrimary(context);
    final textMuted = AbleTheme.textMuted(context);
    final primary = AbleTheme.primary(context);
    final glassCard = AbleTheme.glassCard(context);
    final glassBorder = AbleTheme.glassBorder(context);
    final panelFill = AbleTheme.panelFill(context);
    final iconBubble = AbleTheme.iconBubble(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.createNewPassword),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthTtsToggle(),
                  SizedBox(width: 8),
                  AuthLanguageToggle(),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AbleTheme.backgroundAsset(context),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: AbleTheme.screenOverlay(context)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: glassCard,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: glassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.30)
                              : const Color(0x220AC4E0),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: iconBubble,
                                shape: BoxShape.circle,
                                border: Border.all(color: glassBorder),
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                size: 40,
                                color: primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TtsWrapper(
                              text: '${l10n.setANewPassword}. ${l10n.createSecurePasswordFor(widget.email)}',
                              child: Text(
                                l10n.setANewPassword,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              l10n.createSecurePasswordFor(widget.email),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: textMuted, height: 1.6),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: panelFill,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: glassBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TtsWrapper(
                                  text: l10n.newPasswordLabel,
                                  child: Text(
                                    l10n.newPasswordLabel,
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscure1,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validatePassword,
                                  decoration: InputDecoration(
                                    hintText: l10n.enterYourNewPassword,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() => _obscure1 = !_obscure1);
                                      },
                                      icon: Icon(
                                        _obscure1
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TtsWrapper(
                                  text: l10n.confirmPasswordLabel,
                                  child: Text(
                                    l10n.confirmPasswordLabel,
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscure2,
                                  textInputAction: TextInputAction.done,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validateConfirmPassword,
                                  onFieldSubmitted: (_) {
                                    if (!_isLoading) {
                                      _resetPassword();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: l10n.reEnterYourPassword,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() => _obscure2 = !_obscure2);
                                      },
                                      icon: Icon(
                                        _obscure2
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: panelFill,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: glassBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TtsWrapper(
                                    text: l10n.passwordRequirementsHint,
                                    child: Text(
                                      l10n.passwordRequirementsHint,
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(
                                            color: textMuted,
                                            height: 1.5,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: TtsWrapper(
                              text: l10n.resetPassword,
                              child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AbleTheme.actionGradient(context),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _resetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  disabledForegroundColor: Colors.white70,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        l10n.resetPassword,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: TtsWrapper(
                              text: l10n.backToLogin,
                              child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.go('/login'),
                              child: Text(l10n.backToLogin),
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
          ),
        ],
      ),
    );
  }
}