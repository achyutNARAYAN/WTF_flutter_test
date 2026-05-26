// ============================================================
// Chat Screen — Guru App (& reused by Trainer)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/services/services.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'package:wtf_shared/widgets/widgets.dart';
import 'providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  static const _quickReplies = [
    'Got it 👍',
    'Can we talk at 6?',
    'Share plan?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _sendMessage(String text, User user) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() => _sending = true);

    final chatSvc = ref.read(chatServiceProvider);
    final trainerId = user.assignedTrainerId ?? SeedData.trainer.id;

    AppLogger.log(
      LogTag.chat,
      'Sending message: ${text.substring(0, text.length.clamp(0, 30))}',
    );

    await chatSvc.sendMessage(
      chatId: widget.chatId,
      senderId: user.id,
      receiverId: trainerId,
      text: text.trim(),
    );

    chatSvc.markRead(widget.chatId, user.id);
    setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return const Scaffold();

    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final messages = messagesAsync.value ?? [];

    final trainerId = user.assignedTrainerId ?? SeedData.trainer.id;
    final typingAsync = ref.watch(typingProvider(trainerId));
    final isTyping = typingAsync.value ?? false;

    // Mark read when screen open
    ref.read(chatServiceProvider).markRead(widget.chatId, user.id);

    if (messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home/chat'),
        ),
        title: Row(
          children: [
            UserAvatar(
              url: SeedData.trainer.avatarUrl,
              name: SeedData.trainer.name,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(SeedData.trainer.name, style: AppTextStyles.label),
                Text('Lead Trainer', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
        actions: [
          // Camera icon for join call shortcut
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => context.go('/home/requests'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No messages yet',
                    subtitle: 'Start the conversation.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (isTyping && i == messages.length) {
                        return _TypingBubble();
                      }
                      final msg = messages[i];
                      final isMine = msg.senderId == user.id;
                      return _ChatBubble(
                        message: msg,
                        isMine: isMine,
                        isSystem: msg.senderId == 'system',
                      );
                    },
                  ),
          ),

          // Quick replies
          if (_textController.text.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: 6,
              ),
              child: Row(
                children: _quickReplies
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _sendMessage(r, user),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.memberPrimary,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              r,
                              style: TextStyle(
                                color: AppColors.memberPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Input bar
          _InputBar(
            controller: _textController,
            sending: _sending,
            onSend: () => _sendMessage(_textController.text, user),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  final Message message;
  final bool isMine;
  final bool isSystem;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    this.isSystem = false,
  });

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
    _slide = Tween(
      begin: Offset(widget.isMine ? 0.2 : -0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.memberPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.message.text,
              style: TextStyle(
                color: AppColors.memberPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: widget.isMine
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isMine ? AppColors.memberPrimary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(widget.isMine ? 18 : 4),
                bottomRight: Radius.circular(widget.isMine ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: widget.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.text,
                  style: TextStyle(
                    color: widget.isMine ? Colors.white : AppColors.grey900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(widget.message.createdAt),
                      style: TextStyle(
                        color: widget.isMine
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppColors.grey400,
                        fontSize: 11,
                      ),
                    ),
                    if (widget.isMine) ...[
                      const SizedBox(width: 4),
                      StatusTicks(
                        status: widget.message.status,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}

class StatusTicks extends StatelessWidget {
  final MessageStatus status;
  final Color color;

  const StatusTicks({super.key, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = status == MessageStatus.sent
        ? Icons.done
        : status == MessageStatus.read
        ? Icons.done_all
        : Icons.access_time;

    return Icon(icon, size: 14, color: color);
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            url: SeedData.trainer.avatarUrl,
            name: SeedData.trainer.name,
            radius: 12,
          ),
          const SizedBox(width: 8),
          const TypingIndicator(),
        ],
      ),
    ),
  );
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      left: Spacing.md,
      right: Spacing.md,
      top: 8,
      bottom: MediaQuery.of(context).viewInsets.bottom + 8,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 4,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: 'Type a message…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: controller.text.isNotEmpty
                ? AppColors.memberPrimary
                : AppColors.grey200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: controller.text.isNotEmpty && !sending ? onSend : null,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: controller.text.isNotEmpty
                        ? Colors.white
                        : AppColors.grey400,
                    size: 20,
                  ),
          ),
        ),
      ],
    ),
  );
}
