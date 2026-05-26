// ============================================================
// Home Screen — Guru App
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'package:wtf_shared/widgets/widgets.dart';
import 'providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold();
        return _HomeContent(user: user);
      },
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final User user;
  const _HomeContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingCallsProvider(user.id));
    final upcoming = upcomingAsync.value ?? [];
    final nextCall = upcoming.isNotEmpty ? upcoming.first : null;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppColors.memberPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.memberDark, AppColors.memberPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                UserAvatar(
                                  url: user.avatarUrl,
                                  name: user.name,
                                  radius: 24,
                                  fallbackColor: Colors.white.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hey, ${user.name}! 👋',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Ready to crush it today?',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(Spacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Upcoming call banner
                    if (nextCall != null) _UpcomingCallBanner(call: nextCall),

                    const SizedBox(height: Spacing.md),
                    Text('Quick Actions', style: AppTextStyles.h3),
                    const SizedBox(height: Spacing.sm),

                    // 3 cards
                    _ActionCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Chat with Trainer',
                      subtitle: 'Message Aarav',
                      color: AppColors.memberPrimary,
                      onTap: () => context.go('/home/chat'),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _ActionCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Schedule Call',
                      subtitle: 'Book a session',
                      color: const Color(0xFF7C3AED),
                      onTap: () => context.go('/home/schedule'),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _ActionCard(
                      icon: Icons.history_outlined,
                      title: 'My Sessions',
                      subtitle: 'View past sessions',
                      color: AppColors.success,
                      onTap: () => context.go('/home/sessions'),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _ActionCard(
                      icon: Icons.pending_actions_outlined,
                      title: 'My Requests',
                      subtitle: 'Track call requests',
                      color: AppColors.warning,
                      onTap: () => context.go('/home/requests'),
                    ),

                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
          DevPanel(appName: 'Guru App', version: '1.0.0'),
        ],
      ),
    );
  }
}

class _UpcomingCallBanner extends StatelessWidget {
  final CallRequest call;
  const _UpcomingCallBanner({required this.call});

  @override
  Widget build(BuildContext context) {
    final isJoinable = call.scheduledFor
        .subtract(const Duration(minutes: 10))
        .isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), AppColors.memberPrimary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upcoming Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formatDateTime(call.scheduledFor),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isJoinable)
            FilledButton(
              onPressed: () => context.go('/home/call/${call.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.memberPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Join'),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) {
      _ctrl.reverse();
      widget.onTap();
    },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(width: Spacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTextStyles.label),
                Text(widget.subtitle, style: AppTextStyles.caption),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    ),
  );
}
