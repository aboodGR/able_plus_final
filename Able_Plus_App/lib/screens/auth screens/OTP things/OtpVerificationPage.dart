import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/theme/App_theme.dart';
import 'package:ableplusproject/widgets/AuthLanguageToggle.dart';
import 'package:ableplusproject/widgets/AuthTtsToggle.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterOtp)));
      return;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.otpMustBe6Digits)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.verifyOTP(
        email: widget.email.toLowerCase(),
        token: otp,
        type: OtpType.recovery,
      );

      if (!mounted) return;

      if (response.session == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.invalidOrExpiredOtp)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpVerifiedSuccessfully)),
      );

      context.go('/reset-password?email=${Uri.encodeComponent(widget.email)}');
    } on AuthException catch (e) {
      if (!mounted) return;

      final error = e.message.toLowerCase();
      String message = e.message;

      if (error.contains('token has expired') ||
          error.contains('otp expired') ||
          error.contains('expired')) {
        message = l10n.otpExpired;
      } else if (error.contains('invalid') ||
          error.contains('token not found')) {
        message = l10n.otpInvalid;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.failedToVerifyOtp}: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isResending = true);

    try {
      await supabase.auth.resetPasswordForEmail(widget.email.toLowerCase());

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.otpResentSuccessfully)));
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.failedToResendOtp}: $e')));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);
    final textPrimary = AbleTheme.textPrimary(context);
    final textMuted = AbleTheme.textMuted(context);
    final accent = AbleTheme.accent(context);
    final primary = AbleTheme.primary(context);
    final glassCard = AbleTheme.glassCard(context);
    final glassBorder = AbleTheme.glassBorder(context);
    final panelFill = AbleTheme.panelFill(context);
    final iconBubble = AbleTheme.iconBubble(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.verifyOtp),
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
                              Icons.verified_user_outlined,
                              size: 40,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TtsWrapper(
                            text: '${l10n.enterVerificationCode}. ${l10n.otpSentTo(widget.email)}',
                            child: Text(
                              l10n.enterVerificationCode,
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
                            l10n.otpSentTo(widget.email),
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
                                text: l10n.otpCodeLabel,
                                child: Text(
                                  l10n.otpCodeLabel,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  letterSpacing: 8,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '------',
                                  counterText: '',
                                  prefixIcon: Icon(Icons.password_outlined),
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
                            text: l10n.verifyOtp,
                            child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AbleTheme.actionGradient(context),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyOtp,
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
                                      l10n.verifyOtp,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TtsWrapper(
                            text: l10n.resendOtp,
                            child: TextButton(
                            onPressed: _isResending ? null : _resendOtp,
                            child: _isResending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    l10n.resendOtp,
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TtsWrapper(
                            text: l10n.back,
                            child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => context.go('/forgot-password'),
                            child: Text(l10n.back),
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