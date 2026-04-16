import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter the OTP')));
      return;
    }
    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP must be 6 digits')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.verifyOTP(
        email: widget.email.toLowerCase(),
        token: otp,
        type: OtpType.email,
      );

      if (!mounted) return;

      if (response.session == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid or expired OTP')));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified successfully')),
      );

     // context.push('/reset-password?email=${widget.email}');
     context.push('/reset-password');
    } on AuthApiException catch (e) {
      if (!mounted) return;

      final error = e.message.toLowerCase();
      String message = e.message;

      if (error.contains('token has expored') ||
          error.contains('otp expired') ||
          error.contains('expired')) {
        message = 'The OTP has expired. Please request a new one.';
      } else if (error.contains('invalid') ||
          error.contains('token not found')) {
        message = 'The OTP is invaild. Please check the code and try again.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Faild to verify OTP: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      await supabase.auth.signInWithOtp(
        email: widget.email.toLowerCase(),
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Widget build(BuildContext context) {
    final mutedColor = Colors.grey.shade600;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, size: 72, color: accentColor),
              const SizedBox(height: 24),
              const Text(
                'Enter Verification code',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit code to ${widget.email}',
                style: TextStyle(fontSize: 15, color: mutedColor, height: 1.5),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'OTP Code',
                  hintText: 'Enter 6-digit code',
                  counterText: '',
                  prefixIcon: Icon(Icons.password_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Verifiy OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isResending ? null : _resendOtp,
                  child: _isResending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}