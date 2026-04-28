import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ableplusproject/Models/PostModel.dart';
import '../../theme/app_theme.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatarBg =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE8F7FC);

    final primaryColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    final textColor = isDark ? AbleColors.darkText : AbleColors.lightText;

    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    final mediaGradient = isDark
        ? const LinearGradient(
            colors: [
              Color(0xFF1B2940),
              Color(0xFF223654),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFFDDF2F8),
              Color(0xFFF2FBFE),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: avatarBg,
                      child: Text(
                        (post.authorName ?? 'A').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            post.postType.replaceAll('-', ' • '),
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_horiz_rounded,
                      color: mutedColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  post.content,
                  style: TextStyle(
                    height: 1.5,
                    color: textColor,
                  ),
                ),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: post.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  height: 168,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: mediaGradient,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      size: 52,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Stat(
                      icon: Icons.favorite_border_rounded,
                      label: '${post.likes}',
                    ),
                    const SizedBox(width: 16),
                    _Stat(
                      icon: Icons.mode_comment_outlined,
                      label: '${post.comments}',
                    ),
                    const SizedBox(width: 16),
                    const _Stat(
                      icon: Icons.send_outlined,
                      label: 'Share',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final iconColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    final textColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }
}