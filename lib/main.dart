import 'package:ableplusproject/screens/auth%20screens/OTP%20things/ForgotPasswordEmailPage.dart';
import 'package:ableplusproject/screens/auth%20screens/LoginScreen.dart';
import 'package:ableplusproject/screens/auth%20screens/OTP%20things/OtpVerificationPage.dart';
import 'package:ableplusproject/screens/auth%20screens/OTP%20things/ResetPasswordPage.dart';
import 'package:ableplusproject/screens/auth%20screens/UserType.dart';
import 'package:ableplusproject/screens/auth%20screens/signup(General).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(businesses).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(charities).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(tutor).dart';
import 'package:go_router/go_router.dart';
import 'package:ableplusproject/providers/Auth_provider.dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/theme/App_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    anonKey: 'sb_publishable_zqIDIaY9aG7ZXkAbSk4aJg_-K79DNtY',
    url: 'https://eeefqyaxrfozwbijhsqk.supabase.co',
  );

  runApp(const ProviderScope(child: AblePlusApp()));
}

class AblePlusApp extends ConsumerWidget {
  const AblePlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final AuthState = ref.watch(authProvider);
    return MaterialApp.router(
      title: 'able+',
      debugShowCheckedModeBanner: false,
      theme: AbleTheme.light(),
      darkTheme: AbleTheme.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _buildRouter(AuthState),
    );
  }

  GoRouter _buildRouter(AsyncValue<User?> authState) {
    final isAuthenticated = authState.value != null;
    return GoRouter(
      initialLocation: isAuthenticated ? '/home' : '/login',
      redirect: (context, state) {
        final loggedIn = authState.value != null;
        final location = state.matchedLocation;

        final isLogInRoute = location == '/login';

        final isSignupRoute =
            location == '/signup' || location.startsWith('/signup/');

        final isForgetPasswordRoute = location == '/forget-password';

        final isOtpRoute = location == '/otp';

        final isResetPasswordRoute = location == '/reset-password';

        final isUserType = location == '/user-type';

        final isPublicRoute =
            isLogInRoute ||
            isSignupRoute ||
            isForgetPasswordRoute ||
            isResetPasswordRoute ||
            isOtpRoute ||
            isUserType;

        if (!loggedIn && !isPublicRoute) {
          return '/login';
        }
        if (loggedIn && (isLogInRoute || isSignupRoute)) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/user-type',
          builder: (context, state) => const UserType(),
        ),

        GoRoute(
          path: '/signup',
          builder: (context, state) {
            final type = state.uri.queryParameters['type'] ?? 'user';
            return GeneralSignup(selectedUserType: type);
          },
        ),

        GoRoute(
          path: '/businesses-signup',
          builder: (context, state) => businessesSignup(),
        ),
        GoRoute(
          path: '/charity-signup',
          builder: (context, state) => charitiesSignup(),
        ),
        GoRoute(
          path: '/tutor-signup',
          builder: (context, state) => tutorsSignup(),
        ),
        GoRoute(
          path: '/forget-password',
          builder: (context, state) => ForgotPasswordEmailPage(),
          
          ),
          GoRoute(
            path: '/otp',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
            return OtpVerificationPage(email: email);
            },
            ),
            GoRoute(
              path: '/reset-password',
              builder: (context, state) {
                 final email = state.uri.queryParameters['email'] ?? '';
                 return Resetpasswordpage(email: email);
              },
              )
      ],
    );
  }
}
