import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/theme/App_theme.dart';
import 'package:ableplusproject/widgets/AuthLanguageToggle.dart';
import 'package:ableplusproject/widgets/AuthTtsToggle.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() =>
      _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// يتحقق إنه الإيميل مسجّل بأي وحدة من جداول المستخدمين الأربعة.
  /// بنحتاجه قبل ما نبعت OTP لأن Supabase ما بيرجّع خطأ لو الإيميل مش
  /// موجود (لأسباب أمنية)، فبدون هاد التحقق المستخدم رح يتحوّل لشاشة
  /// OTP بدون فايدة.
  Future<bool> _emailExists(String email) async {
    const tables = ['clients', 'tutors', 'businesses', 'charities'];
    for (final table in tables) {
      try {
        final row = await supabase
            .from(table)
            .select('id')
            .eq('email', email)
            .maybeSingle();
        if (row != null) return true;
      } catch (_) {
        // لو فشل query على جدول معيّن (مثلاً RLS)، نكمّل للتالي
      }
    }
    return false;
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();

    try {
      // ── التحقق من وجود الإيميل قبل إرسال OTP ──
      final exists = await _emailExists(email);
      if (!mounted) return;

      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noAccountFoundForEmail)),
        );
        setState(() => _isLoading = false);
        return;
      }

      await supabase.auth.resetPasswordForEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resetCodeSent)),
      );

      context.go('/otp?email=${Uri.encodeComponent(email)}');
    } on AuthException catch (e) {
      if (!mounted) return;

      String message = e.message;
      final error = e.message.toLowerCase();

      if (error.contains('rate limit')) {
        message = l10n.pleaseWaitBeforeAnotherCode;
      } else if (error.contains('invalid email')) {
        message = l10n.pleaseEnterValidEmail;
      } else if (error.contains('user')) {
        message = l10n.noAccountFoundForEmail;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.failedToSendResetCode}: $e')));
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
        title: Text(l10n.forgotPassword),
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
                                Icons.mark_email_read_outlined,
                                size: 40,
                                color: primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TtsWrapper(
                              text: '${l10n.resetYourPassword}. ${l10n.forgotPasswordSubtitle}',
                              child: Text(
                                l10n.resetYourPassword,
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
                              l10n.forgotPasswordSubtitle,
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
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: l10n.emailHintExample,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return l10n.pleaseEnterEmail;
                                }

                                final emailRegex = RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+$',
                                );
                                if (!emailRegex.hasMatch(email)) {
                                  return l10n.pleaseEnterValidEmail;
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: TtsWrapper(
                              text: l10n.sendOtp,
                              child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AbleTheme.actionGradient(context),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
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
                                        l10n.sendOtp,
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
                                onPressed: () => context.push('/login'),
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