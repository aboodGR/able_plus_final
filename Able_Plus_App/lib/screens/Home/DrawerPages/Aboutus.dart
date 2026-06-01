import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/tts_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const String email = 'ableplusjo1@gmail.com';
  static const String phone = '+962 790 293 429';

  static const List<String> teamMemberNames = [
    'Ahmad Alshakhshir',
    'Abdul Alhajer',
    'Mohammad Alshakhshir',
    'Ibrahim Abusham',
  ];

  static Future<void> _openEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Contact Able+'},
    );
    final bool launched = await launchUrl(emailUri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenEmail)),
      );
    }
  }

  static Future<void> _openPhone(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final String cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final Uri phoneUri = Uri.parse('tel:$cleanPhone');
    final bool launched = await launchUrl(phoneUri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenPhone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);

    return AbleScaffold(
      title: l10n.aboutUs,
      currentIndex: -1,
      showDrawer: true,
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── كارد الصورة + وصف التطبيق ──
            TtsWrapper(
              text: '${l10n.aboutUs}. ${l10n.aboutUsBody}',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AbleTheme.glassCard(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AbleTheme.glassBorder(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/able.png',
                        width: double.infinity,
                        height: 260,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/able.JPG',
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error2, stackTrace2) =>
                              Container(
                            height: 260,
                            decoration: BoxDecoration(
                              color: AbleTheme.iconBubble(context),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.image_outlined,
                                      size: 56,
                                      color: AbleTheme.accent(context)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Able+',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AbleTheme.accent(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        l10n.ableTeam,
                        style: TextStyle(
                            color: accentColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        l10n.aboutUs,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.aboutUsBody,
                      style: TextStyle(
                          fontSize: 16, height: 1.7, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── عنوان قسم الفريق ──
            TtsWrapper(
              text: l10n.ourTeam,
              child: Text(
                l10n.ourTeam,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor),
              ),
            ),

            const SizedBox(height: 12),

            // ── كروت الفريق — كل كارد ملفوف بـ TtsWrapper ──
            GridView.builder(
              itemCount: teamMemberNames.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                return TtsWrapper(
                  text: '${teamMemberNames[index]}, ${l10n.founderCeo}',
                  child: _TeamMemberCard(
                    name: teamMemberNames[index],
                    role: l10n.founderCeo,
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // ── كارد الإيميل ──
            TtsWrapper(
              text: '${l10n.email}: $email',
              child: _InfoCard(
                icon: Icons.email_outlined,
                title: l10n.email,
                value: email,
                onTap: () => _openEmail(context),
              ),
            ),

            const SizedBox(height: 14),

            // ── كارد الهاتف ──
            TtsWrapper(
              text: '${l10n.phone}: $phone',
              child: _InfoCard(
                icon: Icons.phone_outlined,
                title: l10n.phone,
                value: phone,
                onTap: () => _openPhone(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AbleTheme.glassCard(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AbleTheme.glassBorder(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AbleTheme.iconBubble(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded, color: accentColor),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);
    final accentColor = AbleTheme.accent(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AbleTheme.glassCard(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AbleTheme.iconBubble(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.flip(
                flipX: isRtl,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}