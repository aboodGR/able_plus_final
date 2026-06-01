import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileConnectionsScreen extends StatefulWidget {
  const ProfileConnectionsScreen({
    super.key,
    required this.role,
    required this.userId,
    this.initialTab = 'followers',
  });

  final String role;
  final String userId;
  final String initialTab;

  @override
  State<ProfileConnectionsScreen> createState() =>
      _ProfileConnectionsScreenState();
}

class _ProfileConnectionsScreenState extends State<ProfileConnectionsScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;
  List<_ConnectionUser> users = [];

  bool get isFollowersPage => widget.initialTab != 'following';
  IconData get pageIcon => isFollowersPage
      ? Icons.person_add_alt_1_outlined
      : Icons.people_alt_outlined;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // ONE query for either side of the connection list.
      if (isFollowersPage) {
        // Page semantics in your app: "Followers" = people this profile follows
        users = await _loadPeopleThisProfileFollows();
      } else {
        users = await _loadPeopleFollowingThisProfile();
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// People this profile follows.
  /// Only clients can follow, so this returns rows only when the
  /// profile role is 'client'.
  Future<List<_ConnectionUser>> _loadPeopleThisProfileFollows() async {
    if (widget.role != 'client') return [];

    final rows = await supabase
        .from('profile_connections')
        .select(
          'profile_id, profile_role, profile_name, '
          'profile_username, profile_image',
        )
        .eq('follower_id', widget.userId);

    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      return _ConnectionUser(
        id: map['profile_id'].toString(),
        role: map['profile_role']?.toString() ?? 'client',
        name: map['profile_name']?.toString() ??
            map['profile_username']?.toString() ??
            'User',
        username: map['profile_username']?.toString() ?? 'user',
        imageUrl: map['profile_image']?.toString(),
      );
    }).toList();
  }

  /// People following this profile.
  Future<List<_ConnectionUser>> _loadPeopleFollowingThisProfile() async {
    final rows = await supabase
        .from('profile_connections')
        .select(
          'follower_id, follower_role, follower_name, '
          'follower_username, follower_image',
        )
        .eq('profile_id', widget.userId)
        .eq('profile_role', widget.role);

    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      return _ConnectionUser(
        id: map['follower_id'].toString(),
        role: map['follower_role']?.toString() ?? 'client',
        name: map['follower_name']?.toString() ??
            map['follower_username']?.toString() ??
            'User',
        username: map['follower_username']?.toString() ?? 'user',
        imageUrl: map['follower_image']?.toString(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Display strings resolved here (where l10n exists). Logic getters
    // (isFollowersPage) are untouched; only the visible text is localized.
    // NOTE: the "Followers" page intentionally shows who this profile
    // follows — preserved from the original semantics.
    final String pageTitle =
        isFollowersPage ? l10n.followers : l10n.following;
    final String subtitle = isFollowersPage
        ? l10n.followsCountSubtitle(users.length)
        : l10n.followersCountSubtitle(users.length);
    final String emptyText = isFollowersPage
        ? l10n.notFollowingAnyoneProfile
        : l10n.noFollowersProfile;

    return AbleScaffold(
      title: pageTitle,
      currentIndex: 4,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TtsWrapper(
              text: '$pageTitle. $subtitle',
              child: _GlassBox(
                child: ListTile(
                  leading: Icon(pageIcon, color: AbleTheme.primary(context)),
                  title: Text(pageTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AbleTheme.textPrimary(context),
                      )),
                  subtitle: Text(subtitle,
                      style: TextStyle(color: AbleTheme.textMuted(context))),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? _ErrorState(
                        message: errorMessage!, onRetry: _loadConnections)
                    : _ConnectionList(
                        users: users,
                        emptyText: emptyText,
                        onRefresh: _loadConnections,
                      ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionList extends StatelessWidget {
  const _ConnectionList({
    required this.users,
    required this.emptyText,
    required this.onRefresh,
  });

  final List<_ConnectionUser> users;
  final String emptyText;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (users.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 120),
          children: [
            Center(
              child: TtsWrapper(
                text: emptyText,
                child: Text(emptyText,
                    style: TextStyle(color: AbleTheme.textMuted(context))),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = users[index];
          return TtsWrapper(
            text: '${user.name}. @${user.username}. ${user.roleLabel(l10n)}',
            child: _GlassBox(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AbleTheme.iconBubble(context),
                backgroundImage:
                    user.imageUrl != null && user.imageUrl!.isNotEmpty
                        ? NetworkImage(user.imageUrl!)
                        : null,
                child: user.imageUrl == null || user.imageUrl!.isEmpty
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'A',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AbleTheme.accent(context),
                        ),
                      )
                    : null,
              ),
              title: Text(user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AbleTheme.textPrimary(context),
                  )),
              subtitle: Text('@${user.username} • ${user.roleLabel(l10n)}',
                  style: TextStyle(color: AbleTheme.textMuted(context))),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: AbleTheme.textMuted(context)),
              onTap: () => context.push('/profile/${user.role}/${user.id}'),
            ),
            ),
          );
        },
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  const _GlassBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AbleTheme.glassCard(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: AbleColors.danger, size: 44),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AbleTheme.textPrimary(context))),
            const SizedBox(height: 14),
            ElevatedButton(
                onPressed: onRetry, child: Text(l10n.tryAgain)),
          ],
        ),
      ),
    );
  }
}

class _ConnectionUser {
  const _ConnectionUser({
    required this.role,
    required this.id,
    required this.name,
    required this.username,
    this.imageUrl,
  });

  final String role;
  final String id;
  final String name;
  final String username;
  final String? imageUrl;

  String roleLabel(AppLocalizations l10n) {
    switch (role) {
      case 'client':
        return l10n.roleClient;
      case 'tutor':
        return l10n.postRoleTutor;
      case 'business':
        return l10n.postRoleBusiness;
      case 'charity':
        return l10n.postRoleCharity;
      default:
        return role;
    }
  }
}