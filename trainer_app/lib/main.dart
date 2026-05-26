import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/services/services.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'package:wtf_shared/widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  AppLogger.log(LogTag.auth, 'Trainer App started');
  runApp(ProviderScope(child: TrainerApp(authService: authService)));
}

class TrainerApp extends StatelessWidget {
  final AuthService authService;

  const TrainerApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Trainer - WTF Fit',
    theme: AppTheme.build(AppColors.trainerPrimary),
    debugShowCheckedModeBanner: false,
    home: TrainerRoot(authService: authService),
  );
}

class TrainerRoot extends StatefulWidget {
  final AuthService authService;

  const TrainerRoot({super.key, required this.authService});

  @override
  State<TrainerRoot> createState() => _TrainerRootState();
}

class _TrainerRootState extends State<TrainerRoot> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.authService.currentUser;
  }

  Future<void> _login() async {
    await widget.authService.loginAsTrainer();
    AppLogger.log(LogTag.auth, 'Trainer login complete');
    setState(() => _user = widget.authService.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return _LoginScreen(onLogin: _login);
    }
    return TrainerHome(user: user);
  }
}

class _LoginScreen extends StatelessWidget {
  final Future<void> Function() onLogin;

  const _LoginScreen({required this.onLogin});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const RoleBadge(label: 'Trainer', color: AppColors.trainerPrimary),
            const SizedBox(height: Spacing.md),
            Text('Welcome, Aarav', style: AppTextStyles.h1),
            const SizedBox(height: Spacing.sm),
            Text(
              'Review members, answer chats, approve calls, and complete session notes.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: Spacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login),
                label: const Text('Login as Aarav'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}

class TrainerHome extends StatefulWidget {
  final User user;

  const TrainerHome({super.key, required this.user});

  @override
  State<TrainerHome> createState() => _TrainerHomeState();
}

class _TrainerHomeState extends State<TrainerHome> {
  int _tab = 0;
  final _chatService = ChatService();
  final _callService = CallService();
  final _logService = LogService();

  @override
  Widget build(BuildContext context) {
    final screens = [
      _MembersTab(trainer: widget.user),
      _ChatsTab(chatService: _chatService, trainer: widget.user),
      _RequestsTab(callService: _callService, trainer: widget.user),
      _SessionsTab(logService: _logService, trainer: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trainer Console'),
            Text('Trainer - Aarav', style: AppTextStyles.caption),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: Spacing.md),
            child: RoleBadge(label: 'Trainer', color: AppColors.trainerPrimary),
          ),
        ],
      ),
      body: Stack(
        children: [
          screens[_tab],
          const DevPanel(appName: 'Trainer App', version: '1.0.0'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.pending_actions),
            label: 'Requests',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Sessions'),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final User trainer;

  const _MembersTab({required this.trainer});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Spacing.md),
    children: [
      Text('Members', style: AppTextStyles.h2),
      const SizedBox(height: Spacing.md),
      _MemberCard(member: SeedData.member, trainer: trainer),
    ],
  );
}

class _MemberCard extends StatelessWidget {
  final User member;
  final User trainer;

  const _MemberCard({required this.member, required this.trainer});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.md),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        UserAvatar(url: member.avatarUrl, name: member.name, radius: 26),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name, style: AppTextStyles.label),
              Text(member.email, style: AppTextStyles.caption),
              const SizedBox(height: Spacing.xs),
              Text('Assigned to ${trainer.name}', style: AppTextStyles.caption),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.grey400),
      ],
    ),
  );
}

class _ChatsTab extends StatelessWidget {
  final ChatService chatService;
  final User trainer;

  const _ChatsTab({required this.chatService, required this.trainer});

  @override
  Widget build(BuildContext context) {
    final chatId = chatIdFor(SeedData.member.id, trainer.id);
    return StreamBuilder<List<Message>>(
      stream: chatService.messagesStream,
      initialData: chatService.getRecentChats(trainer.id),
      builder: (context, snapshot) {
        final recent = chatService.getRecentChats(trainer.id);
        if (recent.isEmpty) {
          return EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet. Start the conversation.',
            ctaLabel: 'Say hi',
            onCta: () => _openChat(context, chatId),
          );
        }
        final last = recent.first;
        final unread = chatService.unreadCount(chatId, trainer.id);
        return ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            _ChatRow(
              last: last,
              unread: unread,
              onTap: () => _openChat(context, chatId),
            ),
          ],
        );
      },
    );
  }

  void _openChat(BuildContext context, String chatId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TrainerChatScreen(chatId: chatId, trainer: trainer),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final Message last;
  final int unread;
  final VoidCallback onTap;

  const _ChatRow({
    required this.last,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
    leading: Stack(
      children: [
        UserAvatar(
          url: SeedData.member.avatarUrl,
          name: SeedData.member.name,
          radius: 24,
        ),
        if (unread > 0)
          Positioned(
            right: 0,
            top: 0,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: AppColors.trainerPrimary,
              child: Text(
                '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
      ],
    ),
    title: Text(SeedData.member.name, style: AppTextStyles.label),
    subtitle: Text(last.text, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Text(timeAgo(last.createdAt), style: AppTextStyles.caption),
  );
}

class _TrainerChatScreen extends StatefulWidget {
  final String chatId;
  final User trainer;

  const _TrainerChatScreen({required this.chatId, required this.trainer});

  @override
  State<_TrainerChatScreen> createState() => _TrainerChatScreenState();
}

class _TrainerChatScreenState extends State<_TrainerChatScreen> {
  final _chatService = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatService.markRead(widget.chatId, widget.trainer.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.trainer.id,
      receiverId: SeedData.member.id,
      text: text,
    );
    AppLogger.log(LogTag.chat, 'Trainer sent message');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          UserAvatar(
            url: SeedData.member.avatarUrl,
            name: SeedData.member.name,
            radius: 18,
          ),
          const SizedBox(width: Spacing.sm),
          Text(SeedData.member.name),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _TrainerCallScreen(trainer: widget.trainer),
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _chatService.messagesStream,
            initialData: _chatService.getMessages(widget.chatId),
            builder: (_, snapshot) {
              final messages = _chatService.getMessages(widget.chatId);
              if (messages.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No messages yet. Start the conversation.',
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(Spacing.md),
                itemCount: messages.length,
                itemBuilder: (_, index) {
                  final message = messages[index];
                  final mine = message.senderId == widget.trainer.id;
                  return _Bubble(message: message, mine: mine);
                },
              );
            },
          ),
        ),
        _InputBar(
          controller: _controller,
          onSend: () => _send(_controller.text),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final isSystem = message.senderId == 'system';
    return Align(
      alignment: isSystem
          ? Alignment.center
          : (mine ? Alignment.centerRight : Alignment.centerLeft),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isSystem
              ? AppColors.grey200
              : mine
              ? AppColors.trainerPrimary
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mine || isSystem ? Colors.transparent : AppColors.grey200,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: mine ? Colors.white : AppColors.grey900),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type a message',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: controller.text.trim().isEmpty ? null : onSend,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    ),
  );
}

class _RequestsTab extends StatelessWidget {
  final CallService callService;
  final User trainer;

  const _RequestsTab({required this.callService, required this.trainer});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<CallRequest>>(
    stream: callService.requestStream,
    initialData: callService.getRequestsForTrainer(trainer.id),
    builder: (_, snapshot) {
      final requests = callService.getRequestsForTrainer(trainer.id);
      if (requests.isEmpty) {
        return const EmptyState(
          icon: Icons.pending_actions,
          title: 'No call requests yet',
          subtitle: 'DK requests will appear here.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
        itemBuilder: (_, index) => _RequestCard(
          request: requests[index],
          trainer: trainer,
          callService: callService,
        ),
      );
    },
  );
}

class _RequestCard extends StatelessWidget {
  final CallRequest request;
  final User trainer;
  final CallService callService;

  const _RequestCard({
    required this.request,
    required this.trainer,
    required this.callService,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (request.status) {
      CallRequestStatus.pending => AppColors.warning,
      CallRequestStatus.approved => AppColors.success,
      CallRequestStatus.declined => AppColors.error,
      CallRequestStatus.cancelled => AppColors.grey500,
    };
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: _cardDecoration(borderColor: color.withValues(alpha: 0.35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                url: SeedData.member.avatarUrl,
                name: SeedData.member.name,
                radius: 20,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DK - ${formatDateTime(request.scheduledFor)}',
                      style: AppTextStyles.label,
                    ),
                    Text(
                      request.note ?? 'No note',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              RoleBadge(label: request.status.name, color: color),
            ],
          ),
          if (request.status == CallRequestStatus.pending) ...[
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(context),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await callService.approveRequest(request.id);
                      AppLogger.log(LogTag.schedule, 'Approved call request');
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
          if (request.status == CallRequestStatus.approved) ...[
            const SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        _TrainerCallScreen(trainer: trainer, request: request),
                  ),
                ),
                icon: const Icon(Icons.videocam),
                label: const Text('Join Call'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _decline(BuildContext context) async {
    final controller = TextEditingController(text: 'Schedule conflict');
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Decline request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null && reason.isNotEmpty) {
      await callService.declineRequest(request.id, reason);
      AppLogger.log(LogTag.schedule, 'Declined call request');
    }
  }
}

class _TrainerCallScreen extends StatefulWidget {
  final User trainer;
  final CallRequest? request;

  const _TrainerCallScreen({required this.trainer, this.request});

  @override
  State<_TrainerCallScreen> createState() => _TrainerCallScreenState();
}

class _TrainerCallScreenState extends State<_TrainerCallScreen> {
  bool _joined = false;
  bool _micOn = true;
  bool _camOn = true;
  int _seconds = 0;
  DateTime? _startedAt;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _join() {
    // Ensure camera and microphone are enabled when joining
    setState(() {
      _micOn = true;
      _camOn = true;
      _joined = true;
      _startedAt = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    AppLogger.log(LogTag.rtc, 'Trainer camera and mic enabled, joined call');
  }

  void _end() {
    _timer?.cancel();
    final end = DateTime.now();
    final start = _startedAt ?? end.subtract(Duration(seconds: _seconds));
    final log = LogService().createLog(
      memberId: SeedData.member.id,
      trainerId: widget.trainer.id,
      startedAt: start,
      endedAt: end,
    );
    AppLogger.log(LogTag.rtc, 'Trainer ended call');
    _showNotes(log);
  }

  @override
  Widget build(BuildContext context) {
    if (!_joined) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ready to join?')),
        body: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              const Spacer(),
              UserAvatar(
                url: widget.trainer.avatarUrl,
                name: widget.trainer.name,
                radius: 48,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Ready to join? Check mic and camera.',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilterChip(
                    selected: _micOn,
                    label: Text(_micOn ? 'Mic On' : 'Muted'),
                    onSelected: (_) => setState(() => _micOn = !_micOn),
                  ),
                  const SizedBox(width: Spacing.sm),
                  FilterChip(
                    selected: _camOn,
                    label: Text(_camOn ? 'Camera On' : 'Camera Off'),
                    onSelected: (_) => setState(() => _camOn = !_camOn),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _join,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join Call'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final label =
        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _end,
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                padding: const EdgeInsets.all(Spacing.md),
                children: const [
                  _ParticipantTile(name: 'DK', color: AppColors.memberPrimary),
                  _ParticipantTile(
                    name: 'Aarav',
                    color: AppColors.trainerPrimary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: _micOn ? Icons.mic : Icons.mic_off,
                    onTap: () => setState(() => _micOn = !_micOn),
                  ),
                  _CallButton(
                    icon: _camOn ? Icons.videocam : Icons.videocam_off,
                    onTap: () => setState(() => _camOn = !_camOn),
                  ),
                  _CallButton(icon: Icons.flip_camera_ios, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotes(SessionLog log) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          top: Spacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Session Complete', style: AppTextStyles.h2),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Trainer notes'),
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  LogService().updateTrainerNotes(
                    log.id,
                    controller.text.trim(),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Mark as complete'),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }
}

class _ParticipantTile extends StatelessWidget {
  final String name;
  final Color color;

  const _ParticipantTile({required this.name, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: Spacing.md),
    decoration: BoxDecoration(
      color: AppColors.grey900,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: color,
            child: Text(
              name[0],
              style: const TextStyle(color: Colors.white, fontSize: 28),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(name, style: const TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, color: Colors.white),
    style: IconButton.styleFrom(
      backgroundColor: Colors.white24,
      fixedSize: const Size(56, 56),
    ),
  );
}

class _SessionsTab extends StatelessWidget {
  final LogService logService;
  final User trainer;

  const _SessionsTab({required this.logService, required this.trainer});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<SessionLog>>(
    stream: logService.logStream,
    initialData: logService.getLogsForTrainer(trainer.id),
    builder: (_, snapshot) {
      final logs = logService.getLogsForTrainer(trainer.id);
      if (logs.isEmpty) {
        return const EmptyState(
          icon: Icons.history,
          title: 'No sessions yet',
          subtitle: 'Completed calls will appear here.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: logs.length,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
        itemBuilder: (_, index) {
          final log = logs[index];
          return Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDateTime(log.startedAt), style: AppTextStyles.label),
                Text(
                  'Duration: ${log.formattedDuration}',
                  style: AppTextStyles.caption,
                ),
                if (log.rating != null)
                  Text(
                    'Member rating: ${log.rating}/5',
                    style: AppTextStyles.caption,
                  ),
                if (log.memberNotes != null)
                  Text(
                    'Member: ${log.memberNotes}',
                    style: AppTextStyles.caption,
                  ),
                if (log.trainerNotes != null)
                  Text(
                    'Trainer: ${log.trainerNotes}',
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

BoxDecoration _cardDecoration({Color borderColor = AppColors.grey200}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
