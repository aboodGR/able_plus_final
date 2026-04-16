import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Resetpasswordpage extends StatefulWidget {
  final String email;

  const Resetpasswordpage({super.key, required this.email});

  @override
  State<Resetpasswordpage> createState() => _ResetpasswordpageState();
}

class _ResetpasswordpageState extends State<Resetpasswordpage> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _PasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  void dispose(){
    _PasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) return 'Please enter a new Password';
    if(password.length < 6) return 'Password must be at least 6 character';

    if(!RegExp(r'[A-Z]').hasMatch(password)){
      return 'Password must contain at least one uppercase letter';
    }
    if(!RegExp(r'[a-z]').hasMatch(password)){
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)){
      return 'Password must contain at least one number';
    }
    return null;
  }
  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value?.trim() ?? '';
    final password = _PasswordController.text.trim();

    if (confirmPassword.isEmpty) return 'Please confirm your password';
    if (confirmPassword != password) return 'Passwords do not match';

    return null;
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    if(!_formkey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try{
      final session = supabase.auth.currentSession;

      if (session == null) {
        throw Exception('Session expired. Please verify OTP again.');
      }
      await supabase.auth.updateUser(
        UserAttributes(
          password: _PasswordController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully'),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      await supabase.auth.signOut(
        scope: SignOutScope.local,
      );
      if(!mounted) return;
      GoRouter.of(context).go('/login');
    }on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faild to reset password: $e')),
      );
    }finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final mutedColor = Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Password'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formkey,
            child:Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_reset,
                  size: 72,
                ),
                SizedBox(height: 24,),
                Text(
                  'Set a New Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12,),
                Text('Create a new password for ${widget.email}',
                style: TextStyle(
                  fontSize: 15,
                  color: mutedColor,
                  height: 1.5,
                ),
                ),
               SizedBox(height: 32,),
               TextFormField(
                controller: _PasswordController,
                obscureText: _obscure1,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validatePassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed:(){
                      setState(() => _obscure1 = !_obscure1);
                    }, 
                    icon: Icon(
                      _obscure1 ? Icons.visibility_off : Icons.visibility,
                    ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                ),
               ),
               SizedBox(height: 18,),
               TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscure2,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateConfirmPassword,
                onFieldSubmitted: (_){
                  if(!_isLoading){
                    _resetPassword();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: (){
                      setState(() => _obscure2 = !_obscure2);
                    },
                     icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility,
                     ),
                     ),
                     border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                     ),
                ),
               ),
               SizedBox(height: 24,),
               SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                   child: _isLoading
                   ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2,),
                   )
                   : Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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