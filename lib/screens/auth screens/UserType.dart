import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/App_theme.dart';

class UserType extends StatefulWidget {
  const UserType({super.key});

  static const List<_AccountTypeItem> accountTypes = [
    _AccountTypeItem(
      title: 'Charity',
      icon: Icons.volunteer_activism_outlined,
      value: 'charity',
    ),
    _AccountTypeItem(
      title: 'Business Owner',
      icon: Icons.business_outlined,
      value: 'business',
    ),
    _AccountTypeItem(
      title: 'Tutor',
      icon: Icons.school_outlined,
      value: 'tutor',
    ),
    _AccountTypeItem(
      title: 'User',
      icon: Icons.person_outline_rounded,
      value: 'user',
    ),
  ];
  @override
  State<UserType> createState() => _UserTypeState();
}

class _UserTypeState extends State<UserType> {
  void _goToSignup(String type) {
    context.go('/signup?type=$type');
  }

  @override
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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AbleTheme.backgroundAsset(context),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.10)
                  : Colors.white.withOpacity(0.03),
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
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Image.asset(
                                AbleTheme.logoAsset,
                                fit: BoxFit.contain
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Choose Account Type',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Select your account type to continue to sign up.',
                              style: TextStyle(
                                color: mutedColor,
                                height: 1.5,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              itemCount: UserType.accountTypes.length,  
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 1.1,
                                  ),
                              itemBuilder: (context, index) {
                                final item = UserType.accountTypes[index];
                                return _TypeCard(item: item);
                              },
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: TextButton(
                              onPressed: () => context.go('/login'),
                                child: const Text('Back to Login'),
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
          ),
        ],
      ),
    );
  }
}

class _AccountTypeItem {
  final String title;
  final IconData icon;
  final String value;

  const _AccountTypeItem({
    required this.title,
    required this.icon,
    required this.value,
  });
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.item});

  final _AccountTypeItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;

    final accentColor = isDark
        ? AbleColors.darkSecondary
        : AbleColors.lightPrimaryDark;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.go('/signup?type=${item.value}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFD9E8F3),
          ),
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFFF3F8FC).withOpacity(0.9),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 34, color: accentColor),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}