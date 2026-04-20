import 'dart:async';

import 'package:ableplusproject/screens/auth%20screens/LoginScreen.dart';
import 'package:ableplusproject/screens/auth%20screens/OTP%20things/ForgotPasswordEmailPage.dart';
import 'package:ableplusproject/screens/auth%20screens/OTP%20things/OtpVerificationPage.dart';
import 'package:ableplusproject/screens/auth%20screens/OTP%20things/ResetPasswordPage.dart';
import 'package:ableplusproject/screens/auth%20screens/UserType.dart';
import 'package:ableplusproject/screens/auth%20screens/signup(General).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(businesses).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(charities).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(tutor).dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/theme/App_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rxntzxffoquisjjynliy.supabase.co',
    anonKey: 'sb_publishable_BhqZrD_AzKLaRwSIqBPhng_WAg56Wru',
  );

  runApp(const ProviderScope(child: AblePlusApp()));
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AblePlusApp extends ConsumerStatefulWidget {
  const AblePlusApp({super.key});

  @override
  ConsumerState<AblePlusApp> createState() => _AblePlusAppState();
}

class _AblePlusAppState extends ConsumerState<AblePlusApp> {
  late final GoRouter _router;
  late final GoRouterRefreshStream _refreshListenable;

  @override
  void initState() {
    super.initState();

    _refreshListenable = GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    );

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _refreshListenable,
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        final loggedIn = session != null;
        final location = state.matchedLocation;

        final isLoginRoute = location == '/login';
        final isUserTypeRoute = location == '/user-type';
        final isForgotPasswordRoute = location == '/forgot-password';
        final isOtpRoute = location == '/otp';
        final isResetPasswordRoute = location == '/reset-password';
        final isTutorSignupRoute = location == '/tutor-signup';
        final isCharitySignupRoute = location == '/charity-signup';
        final isBusinessSignupRoute = location == '/businesses-signup';

        final isSignupRoute =
            location == '/signup' ||
            location == '/businesses-signup' ||
            location == '/charity-signup' ||
            location == '/tutor-signup';

        final isRecoveryFlow =
            isForgotPasswordRoute || isOtpRoute || isResetPasswordRoute;

        final isPublicRoute =
            isLoginRoute ||
            isUserTypeRoute ||
            isForgotPasswordRoute ||
            isOtpRoute ||
            isResetPasswordRoute ||
            isSignupRoute ||
            isTutorSignupRoute ||
            isCharitySignupRoute ||
            isBusinessSignupRoute;

        if (!loggedIn && !isPublicRoute) {
  return '/login';
}

        
        if (loggedIn && (isOtpRoute || isResetPasswordRoute)) {
  return null;
}

        if (loggedIn && (isLoginRoute || isSignupRoute || isUserTypeRoute)) {
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
          builder: (context, state) => businessSignup(),
        ),
        GoRoute(
          path: '/charity-signup',
          builder: (context, state) => CharitiesSignup(),
        ),
        GoRoute(
          path: '/tutor-signup',
          builder: (context, state) => tutorsSignup(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordEmailPage(),
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
            return ResetPasswordScreen(email: email);
          },
        ),

      ],
    );
  }

  @override
  void dispose() {
    _refreshListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'able+',
      debugShowCheckedModeBanner: false,
      theme: AbleTheme.light(),
      darkTheme: AbleTheme.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}