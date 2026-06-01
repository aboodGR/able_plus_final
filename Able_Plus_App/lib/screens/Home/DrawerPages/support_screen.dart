import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ableplusproject/l10n/app_localizations.dart';
import '../../../widgets/AbleScaffold.dart';
import '../../../widgets/tts_wrapper.dart';
import '../../../theme/app_theme.dart';

String _statusText(AppLocalizations l10n, String? status) {
  switch (status) {
    case 'pending_admin':
      return l10n.statusWaitingForSupport;
    case 'pending_user':
      return l10n.statusSupportReplied;
    case 'closed':
      return l10n.statusClosed;
    default:
      return l10n.statusOpen;
  }
}

String _categoryText(AppLocalizations l10n, String? category) {
  switch (category) {
    case 'Account':
      return l10n.categoryAccount;
    case 'Payments':
      return l10n.categoryPayments;
    case 'Bug':
      return l10n.categoryBug;
    case 'Safety':
      return l10n.categorySafety;
    case 'General':
    default:
      return l10n.categoryGeneral;
  }
}

String _priorityText(AppLocalizations l10n, String? priority) {
  switch (priority) {
    case 'low':
      return l10n.priorityLow;
    case 'high':
      return l10n.priorityHigh;
    case 'urgent':
      return l10n.priorityUrgent;
    case 'normal':
    default:
      return l10n.priorityNormal;
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isCreating = false;
  String _priority = 'normal';
  String _category = 'General';

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _createTicket() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _snack(l10n.pleaseLogInFirst);
      return;
    }

    if (title.isEmpty || message.isEmpty) {
      _snack(l10n.titleAndMessageRequired);
      return;
    }

    setState(() => _isCreating = true);

    try {
      final ticket = await _supabase
          .from('support_tickets')
          .insert({
            'user_id': user.id,
            'title': title,
            'category': _category,
            'priority': _priority,
            'status': 'open',
          })
          .select('id')
          .single();

      await _supabase.from('support_ticket_messages').insert({
        'ticket_id': ticket['id'],
        'sender_type': 'user',
        'sender_id': user.id,
        'message': message,
      });

      if (!mounted) return;
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _priority = 'normal';
        _category = 'General';
      });
      _snack(l10n.supportTicketCreated);
    } catch (e) {
      if (!mounted) return;
      _snack('${l10n.failedToCreateTicket}: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending_admin':
        return Colors.orange;
      case 'pending_user':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return '';
    return DateFormat('MMM d, h:mm a').format(dt.toLocal());
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'low':
        return Colors.teal;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'low':
        return Icons.arrow_downward_rounded;
      case 'high':
        return Icons.arrow_upward_rounded;
      case 'urgent':
        return Icons.priority_high_rounded;
      default:
        return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = _supabase.auth.currentUser;
    final accentColor = AbleTheme.accent(context);
    final textColor = AbleTheme.textPrimary(context);
    final mutedColor = AbleTheme.textMuted(context);

    return AbleScaffold(
      title: l10n.support,
      currentIndex: 0,
      showBackButton: true,
      body: user == null
          ? Center(child: Text(l10n.pleaseLogInToUseSupport))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AbleTheme.glassCard(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AbleTheme.glassBorder(context)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.confirmation_number_outlined,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TtsWrapper(
                              text:
                                  '${l10n.createSupportTicket}. ${l10n.wellGetBackToYou}',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center, // ← التعديل
                                children: [
                                  Text(
                                    l10n.createSupportTicket,
                                    textAlign: TextAlign.center, // ← التعديل
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    l10n.wellGetBackToYou,
                                    textAlign: TextAlign.center, // ← التعديل
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _titleController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: l10n.ticketTitle,
                          hintText: l10n.ticketTitleHint,
                          prefixIcon:
                              Icon(Icons.title_rounded, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: accentColor, width: 2),
                          ),
                          filled: true,
                          fillColor: accentColor.withOpacity(0.04),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TtsWrapper(
                        text: l10n.category,
                        child: Text(
                          l10n.category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CategorySelector(
                        selected: _category,
                        accentColor: accentColor,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      const SizedBox(height: 14),
                      TtsWrapper(
                        text: l10n.priority,
                        child: Text(
                          l10n.priority,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PrioritySelector(
                        selected: _priority,
                        onChanged: (v) => setState(() => _priority = v),
                        priorityColor: _priorityColor,
                        priorityIcon: _priorityIcon,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _messageController,
                        maxLines: 5,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: l10n.messageLabel,
                          hintText: l10n.messageHint,
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 64),
                            child: Icon(Icons.message_outlined,
                                color: accentColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: accentColor, width: 2),
                          ),
                          filled: true,
                          fillColor: accentColor.withOpacity(0.04),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: TtsWrapper(
                          text: l10n.createTicket,
                          child: ElevatedButton.icon(
                            onPressed: _isCreating ? null : _createTicket,
                            icon: _isCreating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(_isCreating
                                ? l10n.creating
                                : l10n.createTicket),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TtsWrapper(
                  text: l10n.myTickets,
                  child: Text(
                    l10n.myTickets,
                    textAlign: TextAlign.center, // ← التعديل
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('support_tickets')
                      .stream(primaryKey: ['id'])
                      .eq('user_id', user.id)
                      .order('last_message_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text(
                          '${l10n.couldNotLoadTickets}: ${snapshot.error}');
                    }

                    final tickets = snapshot.data ?? [];
                    if (tickets.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 48, color: mutedColor),
                              const SizedBox(height: 8),
                              TtsWrapper(
                                text: l10n.noTicketsYet,
                                child: Text(l10n.noTicketsYet,
                                    style: TextStyle(color: mutedColor)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: tickets.map((ticket) {
                        final statusColor =
                            _statusColor(ticket['status']?.toString());
                        final priority =
                            ticket['priority']?.toString() ?? 'normal';
                        return TtsWrapper(
                          text: [
                            ticket['title']?.toString() ??
                                l10n.supportTicketFallback,
                            _statusText(l10n, ticket['status']?.toString()),
                            _priorityText(l10n, priority),
                            _categoryText(
                                l10n, ticket['category']?.toString()),
                            l10n.lastMessageAt(
                                _formatDate(ticket['last_message_at'])),
                          ]
                              .where((p) => p.trim().isNotEmpty)
                              .join('. '),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AbleTheme.glassCard(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AbleTheme.glassBorder(context)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              title: Text(
                                ticket['title']?.toString() ??
                                    l10n.supportTicketFallback,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _ChipLabel(
                                          text: _statusText(l10n,
                                              ticket['status']?.toString()),
                                          color: statusColor,
                                        ),
                                        _ChipLabel(
                                          text:
                                              _priorityText(l10n, priority),
                                          color: _priorityColor(priority),
                                          icon: _priorityIcon(priority),
                                        ),
                                        _ChipLabel(
                                          text: _categoryText(l10n,
                                              ticket['category']?.toString()),
                                          color: accentColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.lastMessageAt(_formatDate(
                                          ticket['last_message_at'])),
                                      style: TextStyle(
                                          color: mutedColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              trailing:
                                  _DirectionalChevron(color: mutedColor),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SupportTicketDetailScreen(
                                      ticketId: ticket['id'].toString(),
                                      initialTitle:
                                          ticket['title']?.toString() ??
                                              l10n.supportTicketFallback,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

class _CategorySelector extends StatelessWidget {
  final String selected;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.accentColor,
    required this.onChanged,
  });

  static const _categories = [
    'General',
    'Account',
    'Payments',
    'Bug',
    'Safety'
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final isSelected = selected == cat;
        return TtsWrapper(
          text: _categoryText(l10n, cat),
          child: GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : accentColor.withOpacity(0.25),
                ),
              ),
              child: Text(
                _categoryText(l10n, cat),
                style: TextStyle(
                  color: isSelected ? Colors.white : accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final Color Function(String) priorityColor;
  final IconData Function(String) priorityIcon;

  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
    required this.priorityColor,
    required this.priorityIcon,
  });

  static const _priorities = ['low', 'normal', 'high', 'urgent'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: _priorities.map((p) {
        final isSelected = selected == p;
        final color = priorityColor(p);
        return Expanded(
          child: TtsWrapper(
            text: _priorityText(l10n, p),
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsetsDirectional.only(
                  end: p == _priorities.last ? 0 : 6,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? color : color.withOpacity(0.25),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      priorityIcon(p),
                      size: 18,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _priorityText(l10n, p),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SupportTicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final String initialTitle;

  const SupportTicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.initialTitle,
  });

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends State<SupportTicketDetailScreen> {
  final _replyController = TextEditingController();
  bool _isSending = false;
  bool _isClosing = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _sendReply() async {
    final l10n = AppLocalizations.of(context)!;
    final message = _replyController.text.trim();
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _snack(l10n.pleaseLogInFirst);
      return;
    }

    if (message.isEmpty) {
      _snack(l10n.pleaseTypeMessage);
      return;
    }

    setState(() => _isSending = true);

    try {
      await _supabase.from('support_ticket_messages').insert({
        'ticket_id': widget.ticketId,
        'sender_type': 'user',
        'sender_id': user.id,
        'message': message,
      });

      if (!mounted) return;
      _replyController.clear();
    } catch (e) {
      if (!mounted) return;
      _snack('${l10n.failedToSendMessage}: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _closeTicket() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isClosing = true);

    try {
      await _supabase.from('support_tickets').update({
        'status': 'closed',
        'closed_at': DateTime.now().toUtc().toIso8601String(),
        'closed_by': 'user',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.ticketId);

      if (!mounted) return;
      _snack(l10n.ticketClosedToast);
    } catch (e) {
      if (!mounted) return;
      _snack('${l10n.failedToCloseTicket}: $e');
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  Future<void> _reopenTicket() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isClosing = true);

    try {
      await _supabase.from('support_tickets').update({
        'status': 'pending_admin',
        'closed_at': null,
        'closed_by': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.ticketId);

      await _supabase.from('support_ticket_messages').insert({
        'ticket_id': widget.ticketId,
        'sender_type': 'user',
        'sender_id': _supabase.auth.currentUser?.id,
        'message': l10n.iReopenedThisTicket,
      });

      if (!mounted) return;
      _snack(l10n.ticketReopenedToast);
    } catch (e) {
      if (!mounted) return;
      _snack('${l10n.failedToReopenTicket}: $e');
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending_admin':
        return Colors.orange;
      case 'pending_user':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return '';
    return DateFormat('MMM d, h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(widget.initialTitle)),
      body: user == null
          ? Center(child: Text(l10n.pleaseLogInToViewTicket))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('support_tickets')
                  .stream(primaryKey: ['id'])
                  .eq('id', widget.ticketId),
              builder: (context, ticketSnapshot) {
                final ticket =
                    (ticketSnapshot.data ?? []).isNotEmpty
                        ? ticketSnapshot.data!.first
                        : null;
                final status = ticket?['status']?.toString();
                final isClosed = status == 'closed';

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TtsWrapper(
                              text: [
                                ticket?['title']?.toString() ??
                                    widget.initialTitle,
                                _statusText(l10n, status),
                                _priorityText(l10n,
                                    ticket?['priority']?.toString()),
                                _categoryText(l10n,
                                    ticket?['category']?.toString()),
                              ]
                                  .where((p) => p.trim().isNotEmpty)
                                  .join('. '),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket?['title']?.toString() ??
                                        widget.initialTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _ChipLabel(
                                        text: _statusText(l10n, status),
                                        color: _statusColor(status),
                                      ),
                                      _ChipLabel(
                                        text: _priorityText(l10n,
                                            ticket?['priority']
                                                ?.toString()),
                                        color: Colors.purple,
                                      ),
                                      _ChipLabel(
                                        text: _categoryText(l10n,
                                            ticket?['category']
                                                ?.toString()),
                                        color: Colors.teal,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TtsWrapper(
                            text: isClosed
                                ? l10n.reopen
                                : l10n.closeTicket,
                            child: TextButton.icon(
                              onPressed: _isClosing
                                  ? null
                                  : isClosed
                                      ? _reopenTicket
                                      : _closeTicket,
                              icon: Icon(isClosed
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded),
                              label: Text(isClosed
                                  ? l10n.reopen
                                  : l10n.closeTicket),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _supabase
                            .from('support_ticket_messages')
                            .stream(primaryKey: ['id'])
                            .eq('ticket_id', widget.ticketId)
                            .order('created_at'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text(
                                    '${l10n.couldNotLoadMessages}: ${snapshot.error}'));
                          }

                          final messages = snapshot.data ?? [];

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final senderType =
                                  msg['sender_type']?.toString();
                              final isMine = senderType == 'user';
                              final isSystem = senderType == 'system';
                              final date =
                                  _formatDate(msg['created_at']);

                              return Align(
                                alignment: isSystem
                                    ? Alignment.center
                                    : isMine
                                        ? AlignmentDirectional.centerEnd
                                        : AlignmentDirectional
                                            .centerStart,
                                child: TtsWrapper(
                                  text: [
                                    isSystem
                                        ? l10n.senderSystem(date)
                                        : isMine
                                            ? l10n.senderYou(date)
                                            : l10n.senderSupport(date),
                                    msg['message']?.toString() ?? '',
                                  ]
                                      .where(
                                          (p) => p.trim().isNotEmpty)
                                      .join('. '),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.78,
                                    ),
                                    margin: const EdgeInsets.only(
                                        bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSystem
                                          ? Colors.amber
                                              .withOpacity(0.15)
                                          : isMine
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .cardColor,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isMine
                                            ? Colors.transparent
                                            : Colors.grey
                                                .withOpacity(0.25),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isSystem
                                              ? l10n.senderSystem(date)
                                              : isMine
                                                  ? l10n.senderYou(date)
                                                  : l10n
                                                      .senderSupport(date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isMine
                                                ? Colors.white70
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          msg['message']?.toString() ??
                                              '',
                                          style: TextStyle(
                                            color: isMine
                                                ? Colors.white
                                                : null,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding:
                            const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor,
                          border: Border(
                              top: BorderSide(
                                  color: Colors.grey.shade300)),
                        ),
                        child: isClosed
                            ? Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          l10n.thisTicketIsClosed)),
                                  ElevatedButton(
                                    onPressed: _isClosing
                                        ? null
                                        : _reopenTicket,
                                    child: Text(l10n.reopen),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _replyController,
                                      minLines: 1,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        hintText: l10n.typeYourMessage,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton.filled(
                                    onPressed: _isSending
                                        ? null
                                        : _sendReply,
                                    icon: _isSending
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                                    strokeWidth: 2),
                                          )
                                        : const Icon(
                                            Icons.send_rounded),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
}

class _ChipLabel extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _ChipLabel({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionalChevron extends StatelessWidget {
  const _DirectionalChevron({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.RTL;
    return Transform.flip(
      flipX: isRtl,
      child: Icon(Icons.chevron_right_rounded, color: color),
    );
  }
}