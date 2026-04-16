import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/theme/App_theme.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() =>
      _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  @override
  final _foemKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _isloading = false;

  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    if (!_foemKey.currentState!.validate()) return;

    setState(() => _isloading = true);

    final email = _emailController.text.trim().toLowerCase();

    try {
      await supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP has been sent to your email')),
      );
      context.push('/otp?email=$email');
    } on AuthException catch (e) {
      if (!mounted) return;

      String message = e.message;
      final error = e.message.toLowerCase();

      if (error.contains('user not found')) {
        message = 'No account found for this email.';
      } else if (error.contains('invalid email')) {
        message = 'Please enter a valid email address.';
      } else if (error.contains('rate limit')) {
        message = 'Please wait before requesting another code.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
    } finally {
      if (mounted) {
        setState(() => _isloading = false);
      }
    }
  }

  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final mutedColor = Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _foemKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 72,
                  color: accentColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter your email and we’ll send a verification code (OTP).',
                  style: TextStyle(
                    fontSize: 15,
                    color: mutedColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    hintText: 'example@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Please enter your email';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(email)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isloading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isloading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
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
