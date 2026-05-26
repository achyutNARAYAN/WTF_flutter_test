// ============================================================
// Chat List Screen — Guru App
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'package:wtf_shared/widgets/widgets.dart';
import 'providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    if (user == null) return const Scaffold();

    // For member, only one chat: with their trainer
    final chatId = chatIdFor(
      user.id,
      user.assignedTrainerId ?? SeedData.trainer.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_chat',
        onPressed: () => context.go('/home/chat/$chatId'),
        child: const Icon(Icons.add),
      ),
      body: _ChatListBody(user: user, chatId: chatId),
    );
  }
}

class _ChatListBody extends ConsumerWidget {
  final User user;
  final String chatId;

  const _ChatListBody({required this.user, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentChatsProvider(user.id));
    final messages = recentAsync.value ?? [];
    final unread = ref.watch(chatServiceProvider).unreadCount(chatId, user.id);

    if (messages.isEmpty) {
      return EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Start the conversation.',
        ctaLabel: 'Say hi 👋',
        onCta: () => context.go('/home/chat/$chatId'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      itemCount: 1, // Member only has one trainer chat
      separatorBuilder: (_, _) => const Divider(indent: 72, height: 1),
      itemBuilder: (_, _) => _ChatTile(
        name: SeedData.trainer.name,
        avatarUrl: SeedData.trainer.avatarUrl,
        lastMessage: messages.first.text,
        time: messages.first.createdAt,
        unread: unread,
        onTap: () => context.go('/home/chat/$chatId'),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime time;
  final int unread;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Spacing.md,
      vertical: 4,
    ),
    leading: Stack(
      children: [
        UserAvatar(url: avatarUrl, name: name, radius: 24),
        if (unread > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.memberPrimary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
    title: Text(
      name,
      style: AppTextStyles.label.copyWith(
        fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
    subtitle: Text(
      lastMessage,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodySmall.copyWith(
        color: unread > 0 ? AppColors.grey800 : AppColors.grey500,
        fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
      ),
    ),
    trailing: Text(timeAgo(time), style: AppTextStyles.caption),
  );
}
