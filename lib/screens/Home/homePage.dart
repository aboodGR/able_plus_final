import 'dart:ui';

import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'postcard.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);
    final isDark = AbleTheme.isDark(context);

    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final accentColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    return AbleScaffold(
      title: 'Able+',
      currentIndex: 0,
      showDrawer: true,
      actions: [
        IconButton(
          onPressed: () => context.push('/home/notifications'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        IconButton(
          onPressed: () => context.push('/profile'),
          icon:FutureBuilder<String?>(
  future: _getProfileImageUrl(),
  builder: (context, snapshot) {
    final imageUrl = snapshot.data;

    return CircleAvatar(
      radius: 14,
      backgroundColor: isDark
          ? Colors.white.withOpacity(0.10)
          : const Color(0xFFE8F7FC),
      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImage(imageUrl)
          : null,
      child: imageUrl == null || imageUrl.isEmpty
          ? Text(
              'A',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            )
          : null,
    );
  },
),
           
          
        ),
      ],
      body: posts.when(
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _QuickCard(
                  title: 'Places',
                  subtitle: 'Verified accessibility',
                  icon: Icons.place_outlined,
                  onTap: () => context.push('/home/places'),
                ),
                _QuickCard(
                  title: 'Tutors',
                  subtitle: 'Learning support',
                  icon: Icons.school_outlined,
                  onTap: () => context.push('/home/tutors'),
                ),
                _QuickCard(
                  title: 'Charities',
                  subtitle: 'Support & volunteering',
                  icon: Icons.volunteer_activism_outlined,
                  onTap: () => context.push('/home/charities'),
                ),
                _QuickCard(
                  title: 'Community',
                  subtitle: 'Questions and updates',
                  icon: Icons.forum_outlined,
                  onTap: () => context.push('/home/community'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Community feed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PostCard(post: post),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AbleTheme.isDark(context);

    final iconBg = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE8F7FC);

    final iconColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;

    final subtitleColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> _getProfileImageUrl() async {
  final supabase = Supabase.instance.client;
  final email = supabase.auth.currentUser?.email;

  if (email == null || email.isEmpty) return null;

  final tables = {
    'clients': 'client_id',
    'tutors': 'tutor_id',
    'businesses': 'business_id',
    'charities': 'charity_id',
  };

  for (final entry in tables.entries) {
    final account = await supabase
        .from(entry.key)
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (account != null) {
      final profile = await supabase
          .from('profiles')
          .select('profile_pic_url')
          .eq(entry.value, account['id'])
          .maybeSingle();

      return profile?['profile_pic_url']?.toString();
    }
  }

  return null;
}