import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class AbleScaffold extends StatelessWidget {
  const AbleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentIndex = 0,
    this.actions,
    this.floatingActionButton,
    this.showDrawer = false,
    this.titleWidget,
  });

  final String title;
  final Widget body;
  final Widget? titleWidget;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showDrawer;

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      drawer: showDrawer ? const _AppDrawer() : null,
      appBar: AppBar(
        title: titleWidget ?? Text(title),
        actions: actions,
        backgroundColor: isDark
            ? const Color(0x99101828)
            : Colors.white.withOpacity(0.55),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
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
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight + 8),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: body,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(currentIndex: currentIndex),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);
    final selectedColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimary;
    final unselectedColor = AbleTheme.textMuted(context);
    final centerBubble = AbleTheme.primary(context);
    final activeBubble = isDark
        ? AbleColors.darkSecondary.withOpacity(0.16)
        : AbleColors.lightPrimary.withOpacity(0.14);

    final items = [
      ('/home', Icons.home_rounded),
      ('/home/map', Icons.location_on_outlined),
      ('/home/create-post', Icons.add_rounded),
      ('/home/messages', Icons.chat_bubble_outline_rounded),
      ('/home/profile/currentUser', Icons.person_outline_rounded),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AbleTheme.glassCard(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AbleTheme.glassBorder(context)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.30)
                  : const Color(0x16000000),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isCenter = index == 2;
                final isSelected = index == currentIndex;
                final icon = items[index].$2;

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.go(items[index].$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isCenter ? 60 : 44,
                    height: isCenter ? 60 : 44,
                    decoration: BoxDecoration(
                      color: isCenter
                          ? centerBubble
                          : isSelected
                              ? activeBubble
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: isCenter ? 32 : 23,
                      color: isCenter
                          ? Colors.white
                          : isSelected
                              ? selectedColor
                              : unselectedColor,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF182437) : Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AbleTheme.iconBubble(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        AbleTheme.logoAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Able+',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      FutureBuilder<Map<String, dynamic>?>(
  future: _getUsername(),
  builder: (context, snapshot) {
    final username = snapshot.data?['username']?.toString();

    return Text(
      username != null && username.isNotEmpty ? '@$username' : '@user',
      style: TextStyle(
        color: mutedColor,
        fontSize: 12,
      ),
    );
  },
),
  
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// MENU
              ...[
                ('My Landings', Icons.bookmark_border_rounded, '/home'),
                ('My Bookings', Icons.calendar_month_outlined, '/home/messages'),
                ('Support', Icons.volunteer_activism_outlined, '/home/messages'),
                ('About Us', Icons.info_outline_rounded,
                    '/home/profile/currentUser'),
                ('Settings', Icons.settings_outlined, '/home/settings'),
              ].map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.$2, color: accentColor),
                  title: Text(item.$1, style: TextStyle(color: textColor)),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: mutedColor),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(item.$3);
                  },
                ),
              ),

              const Spacer(),

              /// LOGOUT
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded,
                    color: AbleColors.danger),
                title: Text('Log out', style: TextStyle(color: textColor)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log out'),
                      content: const Text(
                          'Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text(
                            'Log out',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  try {
                    await Supabase.instance.client.auth.signOut(
                      scope: SignOutScope.local,
                    );

                    if (context.mounted) {
                      Navigator.pop(context); // close drawer
                    }

                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
Future<Map<String, dynamic>?> _getUsername() async {
  final supabase = Supabase.instance.client;
  final email = supabase.auth.currentUser?.email;

  if (email == null || email.isEmpty) return null;

  final tables = [
    'clients',
    'tutors',
    'businesses',
    'charities',
  ];

  for (final table in tables) {
    final result = await supabase
        .from(table)
        .select('username')
        .eq('email', email)
        .maybeSingle();

    if (result != null) return result;
  }

  return null;
}