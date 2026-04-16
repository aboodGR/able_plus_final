import 'package:ableplusproject/theme/App_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/screens/auth screens/ForgotPasswordEmailPage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
    final _formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final supabase = Supabase.instance.client;
    bool obscure = true;
    bool isloading = false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    void dispose() {
      emailController.dispose();
      passwordController.dispose();
      super.dispose();
    }

    String? validateEmail(String? value) {
      final email = value?.trim() ?? '';

      if (email.isEmpty) return 'Email is required';
      if (!emailRegex.hasMatch(email)) return 'Enter a valid email';
      return null;
    }

    String? validatePassword(String? value) {
      final password = value ?? '';
      if (password.isEmpty) return 'Password is required';
      if (password.length < 6) return 'Password must be at least 6 characters';
      return null;
    }

    Future<void> login() async {
      FocusScope.of(context).unfocus();

      if (!_formKey.currentState!.validate()) return;

      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text;

      setState(() => isloading = true);

      try {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;
        if (response.user != null) {
          context.go('/home');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LogIn Failed. Please try again!')),
        );
      } on AuthException catch (e) {
        if (!mounted) return;

        debugPrint('AUTH ERROR: ${e.message}');
        debugPrint('AUTH STATUS: ${e.statusCode}');

        final error = e.message.toLowerCase();
        String message;

        if (error.contains('email not confirmed') ||
            error.contains('email_not_confirmed')) {
          message =
              'Your email is not verified yet. Please check your inbox and verify it first.';
        } else if (error.contains('invalid login credentials')) {
          message = 'Incorrect email or password.';
        } else if (error.contains('user not found')) {
          message = 'No account found for this email. Please sign up first.';
        } else {
          message = e.message;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        if (!mounted) return;
        debugPrint('UNEXPECTED LOGIN ERROR: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      } finally {
        if (mounted) {
          setState(() => isloading = false);
        }
      }
    }

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

      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AbleTheme.backgroundAsset(context),
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Image.asset(
                            AbleTheme.logoAsset,
                            fit: BoxFit.contain,
                           // width: 150,
                           // height: 150,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: validateEmail,
                                  decoration: const InputDecoration(
                                    hintText: 'Email',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: obscure,
                                  textInputAction: TextInputAction.done,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: validatePassword,
                                  onFieldSubmitted: (_) {
                                    if (!isloading) login();
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() => obscure = !obscure);
                                      },
                                      icon: Icon(
                                        obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                         builder: (context) => const ForgotPasswordEmailPage(),
                                       
                                        ),
                                      );
                                    },
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: isloading ? null : login,
                                    child: isloading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Don\'t have an account? ',
                                      style: TextStyle(color: mutedColor),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push('/user-type'),
                                      child: Text(
                                        'Create account',
                                        style: TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

