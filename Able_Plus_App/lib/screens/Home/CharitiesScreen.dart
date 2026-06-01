import 'dart:ui';

import 'package:ableplusproject/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Models/PostModel.dart';
import '../../providers/Post_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/AbleScaffold.dart';
import '../../widgets/tts_wrapper.dart';
import '../../widgets/VipBadge.dart';

class CharitiesScreen extends ConsumerStatefulWidget {
  const CharitiesScreen({super.key});

  @override
  ConsumerState<CharitiesScreen> createState() => _CharitiesScreenState();
}

class _CharitiesScreenState extends ConsumerState<CharitiesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);
    final titleColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    final feed = ref.watch(charityPostsProvider);

    return AbleScaffold(
      title: l10n.charities,
      currentIndex: 0,
      showBackButton: true,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(charityPostsProvider);
          await ref.read(charityPostsProvider.future);
        },
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              Icon(Icons.error_outline, size: 48, color: mutedColor),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  l10n.couldNotLoadCharityPosts(err.toString()),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor),
                ),
              ),
            ],
          ),
          data: (allItems) {
            final query = _query.trim().toLowerCase();
            final items = query.isEmpty
                ? allItems
                : allItems
                    .where((p) =>
                        (p.authorName ?? '').toLowerCase().contains(query))
                    .toList();

            if (allItems.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  _Header(
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    count: 0,
                  ),
                  const SizedBox(height: 32),
                  _EmptyState(
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.isEmpty ? 3 : items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                    child: _Header(
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      count: allItems.length,
                    ),
                  );
                }

                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                    child: _CharitySearchField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      onClear: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                  );
                }

                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 40, 8, 0),
                    child: TtsWrapper(
                      text: l10n.noCharitiesMatchSearch,
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 44, color: mutedColor),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noCharitiesMatchSearch,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final post = items[index - 2];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CharityPostCard(post: post),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- search field --------------------------------------------

class _CharitySearchField extends StatelessWidget {
  const _CharitySearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TtsWrapper(
      text: l10n.searchCharities,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: l10n.searchCharities,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: AbleTheme.glassCard(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AbleTheme.glassBorder(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AbleTheme.glassBorder(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AbleTheme.accent(context)),
          ),
        ),
      ),
    );
  }
}

// --- header --------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.titleColor,
    required this.mutedColor,
    required this.count,
  });

  final Color titleColor;
  final Color mutedColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TtsWrapper(
      text:
          '${l10n.supportACharity}. ${count == 0 ? l10n.charitiesWillShareHere : l10n.campaignsSubtitle(count)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // ← التعديل
        children: [
          Text(
            l10n.supportACharity,
            textAlign: TextAlign.center, // ← التعديل
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count == 0
                ? l10n.charitiesWillShareHere
                : l10n.campaignsSubtitle(count),
            textAlign: TextAlign.center, // ← التعديل
            style: TextStyle(color: mutedColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// --- empty state ---------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.titleColor, required this.mutedColor});

  final Color titleColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);
    final iconBg =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE8F7FC);
    final accent =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;

    return TtsWrapper(
      text: '${l10n.noCharityPostsYet}. ${l10n.whenCharitiesPostHint}',
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(
              Icons.volunteer_activism_outlined,
              size: 44,
              color: accent,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.noCharityPostsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.whenCharitiesPostHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// --- the post card -------------------------------------------

class CharityPostCard extends ConsumerStatefulWidget {
  const CharityPostCard({super.key, required this.post});

  final PostModel post;

  @override
  ConsumerState<CharityPostCard> createState() => _CharityPostCardState();
}

class _CharityPostCardState extends ConsumerState<CharityPostCard> {
  late String localContent;
  late List<String> localImages;
  late String? localDonationLink;

  bool _hasCheckedOwnership = false;
  bool _isOwnPost = false;
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    localContent = widget.post.content;
    localImages = List<String>.from(widget.post.images ?? []);
    localDonationLink = widget.post.donationLink;
    _checkIfOwnPost();
  }

  @override
  void didUpdateWidget(covariant CharityPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.content != widget.post.content ||
        oldWidget.post.images != widget.post.images ||
        oldWidget.post.donationLink != widget.post.donationLink) {
      localContent = widget.post.content;
      localImages = List<String>.from(widget.post.images ?? []);
      localDonationLink = widget.post.donationLink;
      _hasCheckedOwnership = false;
      _isOwnPost = false;
      _checkIfOwnPost();
    }
  }

  Future<void> _checkIfOwnPost() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final email = user?.email;
      if (email == null || email.isEmpty) {
        if (mounted) setState(() => _hasCheckedOwnership = true);
        return;
      }

      final row = await supabase
          .from('charities')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      final viewerCharityId = row?['id']?.toString();
      final isOwn = viewerCharityId != null &&
          viewerCharityId == widget.post.authorId &&
          widget.post.postType == 'charity';

      if (!mounted) return;
      setState(() {
        _hasCheckedOwnership = true;
        _isOwnPost = isOwn;
      });
    } catch (e) {
      debugPrint('CHARITY OWNER CHECK ERROR: $e');
      if (mounted) setState(() => _hasCheckedOwnership = true);
    }
  }

  String _formatPostTime(AppLocalizations l10n, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _openDonationLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final raw = (localDonationLink ?? '').trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.charityNoDonationLink)),
      );
      return;
    }
    var normalized = raw;
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidDonationLink)),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenDonationLink)),
      );
    }
  }

  Future<void> _openMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = AbleTheme.isDark(context);
        final sheetColor = isDark ? const Color(0xFF182437) : Colors.white;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _isOwnPost
                  ? [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(l10n.editPost),
                        onTap: () {
                          Navigator.pop(context);
                          _openEditSheet(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        title: Text(
                          l10n.deletePost,
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDelete(context);
                        },
                      ),
                    ]
                  : [
                      ListTile(
                        leading: const Icon(Icons.flag_outlined,
                            color: Colors.orange),
                        title: Text(
                          l10n.reportPost,
                          style: const TextStyle(color: Colors.orange),
                        ),
                        subtitle: Text(l10n.reportPostSubtitle),
                        onTap: () {
                          Navigator.pop(context);
                          _openReportSheet(context);
                        },
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openReportSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    bool isSending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
            final isDark = AbleTheme.isDark(sheetContext);
            final sheetColor = isDark ? const Color(0xFF182437) : Colors.white;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            l10n.reportPost,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AbleTheme.textPrimary(sheetContext),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.reportPostBody,
                        style: TextStyle(
                          color: AbleTheme.textMuted(sheetContext),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: reasonController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: l10n.reportPostReasonHint,
                          filled: true,
                          fillColor: AbleTheme.panelFill(sheetContext),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSending
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSending
                                  ? null
                                  : () async {
                                      final reason =
                                          reasonController.text.trim();
                                      if (reason.isEmpty) {
                                        ScaffoldMessenger.of(sheetContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                l10n.pleaseWriteShortReason),
                                          ),
                                        );
                                        return;
                                      }
                                      setSheetState(() => isSending = true);
                                      final ok = await _submitReport(reason);
                                      if (!sheetContext.mounted) return;
                                      Navigator.pop(sheetContext);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(ok
                                              ? l10n.reportSentThanks
                                              : l10n
                                                  .couldNotSendReportTryAgain),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              icon: isSending
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_outlined, size: 18),
                              label: Text(l10n.submit),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    reasonController.dispose();
  }

  Future<bool> _submitReport(String reason) async {
    try {
      final supabase = Supabase.instance.client;
      final viewer = await ref.read(viewerProvider.future);
      if (viewer == null) return false;

      await supabase.from('post_reports').insert({
        'post_id': widget.post.id,
        'reported_by': viewer.id,
        'message': reason,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('REPORT ERROR: $e');
      return false;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deletePostQuestion),
        content: Text(l10n.deletePostBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('posts').delete().eq('id', widget.post.id);

      if (!mounted) return;
      setState(() => _isDeleted = true);

      ref.invalidate(charityPostsProvider);
      ref.invalidate(postsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.deletePostFailedError(e.toString()))),
      );
    }
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final contentController = TextEditingController(text: localContent);
    final donationController =
        TextEditingController(text: localDonationLink ?? '');
    XFile? pickedImage;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomPadding =
                MediaQuery.of(sheetContext).viewInsets.bottom;
            final isDark = AbleTheme.isDark(sheetContext);
            final sheetColor = isDark ? const Color(0xFF182437) : Colors.white;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editCharityPost,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AbleTheme.textPrimary(sheetContext),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: contentController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: l10n.editYourPost,
                            filled: true,
                            fillColor: AbleTheme.panelFill(sheetContext),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: donationController,
                          decoration: InputDecoration(
                            hintText: l10n.donationLinkOptional,
                            filled: true,
                            fillColor: AbleTheme.panelFill(sheetContext),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (pickedImage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AbleTheme.panelFill(sheetContext),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.image_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.newImageLabel(pickedImage!.name),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AbleTheme.textMuted(sheetContext),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setSheetState(
                                    () => pickedImage = null,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (localImages.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              localImages.first,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Text(
                            l10n.noImageAttached,
                            style: TextStyle(
                              color: AbleTheme.textMuted(sheetContext),
                            ),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picker = ImagePicker();
                                  final image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (image == null) return;
                                  setSheetState(() => pickedImage = image);
                                },
                          icon: const Icon(Icons.image_outlined),
                          label: Text(l10n.changeImage),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setSheetState(() => isSaving = true);
                                    final ok = await _saveEdits(
                                      newContent:
                                          contentController.text.trim(),
                                      newDonationLink:
                                          donationController.text.trim(),
                                      newImage: pickedImage,
                                    );
                                    if (!sheetContext.mounted) return;
                                    setSheetState(() => isSaving = false);
                                    if (ok) {
                                      Navigator.pop(sheetContext);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.postUpdated),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(sheetContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.updateFailedTryAgain,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(l10n.saveChanges),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    contentController.dispose();
    donationController.dispose();
  }

  Future<bool> _saveEdits({
    required String newContent,
    required String newDonationLink,
    required XFile? newImage,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('posts').update({
        'content': newContent,
        'donation_link': newDonationLink.isEmpty ? null : newDonationLink,
      }).eq('id', widget.post.id);

      String? newImageUrl;
      if (newImage != null) {
        final bytes = await newImage.readAsBytes();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${newImage.name}';
        final storagePath = 'post_media/${widget.post.id}/$fileName';

        await supabase.storage.from('post_media').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        newImageUrl =
            supabase.storage.from('post_media').getPublicUrl(storagePath);

        await supabase.from('media').delete().eq('post_id', widget.post.id);
        await supabase.from('media').insert({
          'post_id': widget.post.id,
          'media_url': newImageUrl,
          'media_type': 'image',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      if (!mounted) return true;
      setState(() {
        localContent = newContent;
        localDonationLink = newDonationLink.isEmpty ? null : newDonationLink;
        if (newImageUrl != null) {
          localImages = [newImageUrl!];
        }
      });

      ref.invalidate(charityPostsProvider);
      ref.invalidate(postsProvider);
      return true;
    } catch (e) {
      debugPrint('CHARITY EDIT ERROR: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isDark = AbleTheme.isDark(context);

    final avatarBg =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE8F7FC);
    final accentColor =
        isDark ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;
    final textColor = isDark ? AbleColors.darkText : AbleColors.lightText;
    final mutedColor =
        isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;

    final hasProfileImage = widget.post.authorImage != null &&
        widget.post.authorImage!.isNotEmpty;
    final hasPostImage = localImages.isNotEmpty;
    final hasDonationLink = (localDonationLink ?? '').trim().isNotEmpty;

    final donationGradient = isDark
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0992C2), Color(0xFF0AC4E0)],
          )
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF0B82D2),
              Color(0xFF45AEDD),
              Color(0xFF7BD8E8),
            ],
          );

    final spokenParts = <String>[
      widget.post.authorName ?? l10n.charityFallbackName,
      l10n.placeKindCharity,
      _formatPostTime(l10n, widget.post.createdAt),
    ];
    if (localContent.isNotEmpty) spokenParts.add(localContent);
    spokenParts.add(hasDonationLink ? l10n.donateNow : l10n.noDonationLink);
    final spokenText =
        spokenParts.where((p) => p.trim().isNotEmpty).join('. ');

    return VipGoldFrame(
      isVip: widget.post.isVip,
      child: TtsWrapper(
        text: spokenText,
        child: ClipRRect(
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
                        InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () {
                            if (widget.post.authorId.isNotEmpty) {
                              context.push(
                                '/profile/charity/${widget.post.authorId}',
                              );
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: avatarBg,
                            backgroundImage: hasProfileImage
                                ? NetworkImage(widget.post.authorImage!)
                                : null,
                            child: hasProfileImage
                                ? null
                                : Text(
                                    (widget.post.authorName ?? 'C')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.authorName ??
                                    l10n.charityFallbackName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.volunteer_activism_outlined,
                                          size: 12,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.placeKindCharity,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.post.isVip) ...[
                                    const SizedBox(width: 7),
                                    const VipBadge(compact: true),
                                  ],
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _formatPostTime(
                                          l10n, widget.post.createdAt),
                                      style: TextStyle(
                                        color: mutedColor,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_hasCheckedOwnership)
                          IconButton(
                            onPressed: () => _openMenu(context),
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: mutedColor,
                            ),
                          ),
                      ],
                    ),
                    if (hasPostImage) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: localImages.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 180,
                            color: avatarBg,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 160,
                            color: avatarBg,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: mutedColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (localContent.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        localContent,
                        style: TextStyle(height: 1.5, color: textColor),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: hasDonationLink ? donationGradient : null,
                          color: hasDonationLink ? null : avatarBg,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: hasDonationLink
                              ? [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: hasDonationLink
                              ? () => _openDonationLink(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: mutedColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          icon: Icon(
                            hasDonationLink
                                ? Icons.favorite_rounded
                                : Icons.link_off_rounded,
                            size: 18,
                          ),
                          label: Text(
                            hasDonationLink
                                ? l10n.donateNow
                                : l10n.noDonationLink,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}