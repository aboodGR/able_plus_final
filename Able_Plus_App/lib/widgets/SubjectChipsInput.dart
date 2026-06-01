import 'package:flutter/material.dart';

import 'package:ableplusproject/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Multi-select chip input for tutor subjects.
///
/// Features:
///   - Type a subject and press enter/comma to add it as a chip
///   - Tap a chip's X to remove it
///   - Tap a suggestion chip below to quickly add a common subject
class SubjectChipsInput extends StatefulWidget {
  const SubjectChipsInput({
    super.key,
    required this.onChanged,
    this.suggestions = const [
      'Math',
      'English',
      'Arabic',
      'Science',
      'Programming',
      'Music',
      'Art',
    ],
  });

  final void Function(List<String> subjects) onChanged;
  final List<String> suggestions;

  @override
  State<SubjectChipsInput> createState() => _SubjectChipsInputState();
}

class _SubjectChipsInputState extends State<SubjectChipsInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _subjects = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addSubject(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return;

    // Case-insensitive duplicate check
    final lower = clean.toLowerCase();
    if (_subjects.any((s) => s.toLowerCase() == lower)) {
      _controller.clear();
      return;
    }

    setState(() {
      _subjects.add(clean);
      _controller.clear();
    });

    widget.onChanged(_subjects);
  }

  void _removeSubject(String subject) {
    setState(() {
      _subjects.remove(subject);
    });
    widget.onChanged(_subjects);
  }

  void _onSubmitted(String value) {
    // Allow commas to act as a separator: "Math, Science" → 2 chips
    for (final part in value.split(',')) {
      _addSubject(part);
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark
        ? AbleColors.darkSecondary
        : AbleColors.lightPrimaryDark;
    final mutedColor = isDark
        ? AbleColors.darkTextMuted
        : AbleColors.lightTextMuted;
    final textColor = isDark ? AbleColors.darkText : AbleColors.lightText;

    final availableSuggestions = widget.suggestions
        .where((s) =>
            !_subjects.any((added) => added.toLowerCase() == s.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected chips + text input inside one rounded container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF3F8FC).withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFD9E8F3),
            ),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._subjects.map(
                (s) => Chip(
                  label: Text(s),
                  onDeleted: () => _removeSubject(s),
                  deleteIconColor: accentColor,
                  backgroundColor: accentColor.withOpacity(0.14),
                  labelStyle: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: accentColor.withOpacity(0.3)),
                  ),
                ),
              ),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmitted: _onSubmitted,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _subjects.isEmpty
                          ? l10n.addSubjectHint
                          : l10n.addAnotherHint,
                      hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Suggestions
        if (availableSuggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            l10n.suggestions,
            style: TextStyle(
              color: mutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: availableSuggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s),
                    onPressed: () => _addSubject(s),
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white,
                    labelStyle: TextStyle(color: textColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: accentColor.withOpacity(0.3)),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}