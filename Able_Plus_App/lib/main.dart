import 'dart:async';
import 'package:ableplusproject/screens/Home/DrawerPages/Aboutus.dart';
import 'package:ableplusproject/providers/theme_providers.dart';
import 'package:ableplusproject/screens/Home/homePage.dart';
import 'package:ableplusproject/screens/Vip/vip_membership_screen.dart';
import 'package:ableplusproject/Models/BusinessModel.dart';
import 'package:ableplusproject/screens/Home/CharitiesScreen.dart';
import 'package:ableplusproject/screens/Home/businesses/business_detail_screen.dart';
import 'package:ableplusproject/screens/Home/businesses/businesses_screen.dart';
import 'package:ableplusproject/screens/Home/tutor/TutorScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ableplusproject/screens/Home/DrawerPages/support_screen.dart';
import 'package:ableplusproject/screens/Home/DrawerPages/my_activity_screen.dart';
import 'package:ableplusproject/screens/Home/map/map.dart';
import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/screens/Messages/chat_screen.dart';
import 'package:ableplusproject/screens/Messages/messages_screen.dart';
import 'package:ableplusproject/screens/Post/CreatePost.dart';
import 'package:ableplusproject/screens/Settings/settings.dart';
import 'package:ableplusproject/screens/auth%20screens/LoginScreen.dart';
import 'package:ableplusproject/screens/auth%20screens/OTP%20things/ForgotPasswordEmailPage.dart';
import 'package:ableplusproject/screens/auth%20screens/OTP%20things/OtpVerificationPage.dart';
import 'package:ableplusproject/screens/auth%20screens/OTP%20things/ResetPasswordPage.dart';
import 'package:ableplusproject/screens/auth%20screens/UserType.dart';
import 'package:ableplusproject/screens/auth%20screens/signup(General).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(businesses).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(charities).dart';
import 'package:ableplusproject/screens/auth%20screens/signup(tutor).dart';
import 'package:ableplusproject/screens/notification/NotificationsScreen.dart';
import 'package:ableplusproject/screens/profile/profile.dart';
import 'package:ableplusproject/screens/profile/profile_connections.dart';
import 'package:ableplusproject/screens/usertouser/Find%20&%20Share.dart';
import 'package:ableplusproject/screens/usertouser/FindAndSharePostDetails.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
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
  bool _forceLoginForInitialProtectedUrl = false;
  bool _isSigningOutForInitialUrl = false;

  @override
  void initState() {
    super.initState();

    final initialLocation = _initialLocationFromBrowserUrl();
    _forceLoginForInitialProtectedUrl =
        kIsWeb && !_isPublicLocation(initialLocation);

    _refreshListenable = GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    );

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: _refreshListenable,

      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        final loggedIn = session != null;
        final location = state.matchedLocation;

        final isRootRoute = location == '/';
        final isLoginRoute = location == '/login';
        final isUserTypeRoute = location == '/user-type';

        final isForgotPasswordRoute = location == '/forgot-password';
        final isOtpRoute = location == '/otp';
        final isResetPasswordRoute = location == '/reset-password';

        final isSignupRoute =
            location == '/signup' ||
            location == '/businesses-signup' ||
            location == '/charity-signup' ||
            location == '/tutor-signup';

        final isPublicRoute =
            isRootRoute ||
            isLoginRoute ||
            isUserTypeRoute ||
            isForgotPasswordRoute ||
            isOtpRoute ||
            isResetPasswordRoute ||
            isSignupRoute;

        // Web deep-link guard: if someone copies a protected URL and opens it
        // in a fresh tab/window, show Login instead of restoring the old
        // Supabase session and opening the app directly.
        if (_forceLoginForInitialProtectedUrl) {
          _forceLoginForInitialProtectedUrl = false;
          _isSigningOutForInitialUrl = true;
          unawaited(
            Supabase.instance.client.auth.signOut().whenComplete(() {
              _isSigningOutForInitialUrl = false;
            }),
          );
          return '/login';
        }

        if (_isSigningOutForInitialUrl && isLoginRoute) {
          return null;
        }

        if (!loggedIn && !isPublicRoute) {
          return '/login';
        }

        if (loggedIn &&
            (isRootRoute || isLoginRoute || isSignupRoute || isUserTypeRoute)) {
          return '/home';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) {
            final session = Supabase.instance.client.auth.currentSession;
            return session == null ? '/login' : '/home';
          },
        ),

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

        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

        GoRoute(
          path: '/home/settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        GoRoute(
          path: '/home/vip',
          builder: (context, state) => const VipMembershipScreen(),
        ),

        GoRoute(
          path: '/home/vip/payment',
          builder: (context, state) => const VipDemoPaymentScreen(),
        ),

        GoRoute(
          path: '/home/vip/success',
          builder: (context, state) => VipSuccessScreen(
            expiresAt: state.extra is DateTime ? state.extra as DateTime : null,
          ),
        ),

        GoRoute(
          path: '/home/create-post',
          builder: (context, state) => const CreatePostScreen(),
        ),

        GoRoute(
          path: '/home/messages',
          builder: (context, state) => const MessagesScreen(),
        ),

        GoRoute(
          path: '/home/map',
          builder: (context, state) => const MapScreen(),
        ),

        GoRoute(
          path: '/home/places',
          builder: (context, state) => const BusinessesScreen(),
        ),

        GoRoute(
          path: '/home/places/:id',
          builder: (context, state) {
            final business = state.extra;
            if (business is BusinessModel) {
              return BusinessDetailScreen(business: business);
            }
            return const BusinessesScreen();
          },
        ),

        GoRoute(
          path: '/home/tutors',
          builder: (context, state) => const TutorScreen(),
        ),

        GoRoute(
          path: '/home/charities',
          builder: (context, state) => const CharitiesScreen(),
        ),

        GoRoute(
          path: '/home/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/home/support',
          builder: (context, state) => const SupportScreen(),
        ),

        GoRoute(
          path: '/home/my-activity',
          builder: (context, state) => const MyActivityScreen(),
        ),
        GoRoute(
          path: '/home/aboutus',
          builder: (context, state) => const AboutUsPage(),
        ),

       GoRoute(
          path: '/home/Findandshare',
          builder: (context, state) => const FindAndShareScreen(),
        ),

        GoRoute(
          path: '/home/Findandshare/post/:id',
          builder: (context, state) {
            final postId = state.pathParameters['id']!;

            return FindAndSharePostDetailsScreen(postId: postId);
          },
        ),

        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const ProfileScreen(currentUserProfile: true),
        ),

        GoRoute(
          path: '/profile/:role/:userId/connections',
          builder: (context, state) {
            return ProfileConnectionsScreen(
              role: state.pathParameters['role']!,
              userId: state.pathParameters['userId']!,
              initialTab: state.uri.queryParameters['tab'] ?? 'followers',
            );
          },
        ),

        GoRoute(
          path: '/profile/:role/:id',
          builder: (context, state) => ProfileScreen(
            role: state.pathParameters['role'],
            userId: state.pathParameters['id'],
          ),
        ),

        GoRoute(
          path: '/home/profile/currentUser',
          redirect: (context, state) => '/profile',
        ),

        GoRoute(
          path: '/home/profile/:role/:id',
          redirect: (context, state) {
            final role = state.pathParameters['role'];
            final id = state.pathParameters['id'];
            return '/profile/$role/$id';
          },
        ),

        GoRoute(
          path: '/chat',
          builder: (context, state) {
            final data = state.extra;

            if (data is! Map<String, dynamic>) {
              return const MessagesScreen();
            }

            return ChatScreen(
              conversationId: data['conversationId'].toString(),
              otherName: data['otherName'].toString(),
              otherImage: data['otherImage']?.toString(),
              otherId: data['otherId']?.toString() ?? '',
              otherType: data['otherType']?.toString() ?? '',
            );
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

  String _initialLocationFromBrowserUrl() {
    final base = Uri.base;
    final hashLocation = base.fragment.trim();

    // Flutter web with hash URLs stores the route after #.
    // Example: http://localhost:65287/#/home => fragment is /home.
    if (hashLocation.startsWith('/')) {
      return Uri.parse(hashLocation).path;
    }

    return base.path.isEmpty ? '/' : base.path;
  }

  bool _isPublicLocation(String location) {
    final path = Uri.tryParse(location)?.path ?? location;

    if (path == '/' || path == '/login') return true;
    if (path == '/user-type') return true;
    if (path == '/forgot-password') return true;
    if (path == '/otp') return true;
    if (path == '/reset-password') return true;
    if (path == '/signup') return true;
    if (path == '/businesses-signup') return true;
    if (path == '/charity-signup') return true;
    if (path == '/tutor-signup') return true;
    return false;
  }

 Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);
    final isColorBlind = ref.watch(colorblindModeProvider);

    Widget app = MaterialApp.router(
      title: 'able+',
      debugShowCheckedModeBanner: false,
      theme: AbleTheme.light(),
      darkTheme: AbleTheme.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,

      // ── Localisation ──
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );

    // ── Color Blind Filter (Deuteranopia) ──
    if (isColorBlind) {
      app = ColorFiltered(
        colorFilter: const ColorFilter.matrix(deuteranopiaMatrix),
        child: app,
      );
    }

    return app;
  }
}
