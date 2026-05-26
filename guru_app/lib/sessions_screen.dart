// ============================================================
// Sessions Screen — Guru App
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'package:wtf_shared/widgets/widgets.dart';
import 'providers.dart';

enum _Filter { all, week, month }

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Scaffold();

    final logsAsync = ref.watch(memberLogsProvider(user.id));
    final allLogs = logsAsync.value ?? [];

    final now = DateTime.now();
    final logs = switch (_filter) {
      _Filter.all => allLogs,
      _Filter.week =>
        allLogs.where((l) => now.difference(l.startedAt).inDays <= 7).toList(),
      _Filter.month =>
        allLogs.where((l) => now.difference(l.startedAt).inDays <= 30).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  active: _filter == _Filter.all,
                  onTap: () => setState(() => _filter = _Filter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Last 7 Days',
                  active: _filter == _Filter.week,
                  onTap: () => setState(() => _filter = _Filter.week),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'This Month',
                  active: _filter == _Filter.month,
                  onTap: () => setState(() => _filter = _Filter.month),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: logs.isEmpty
                ? EmptyState(
                    icon: Icons.history_outlined,
                    title: 'No sessions yet',
                    subtitle: 'Schedule your first call.',
                    ctaLabel: 'Schedule Now',
                    onCta: () => context.go('/home/schedule'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _SessionCard(log: logs[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.memberPrimary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.memberPrimary : AppColors.grey300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.grey700,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );
}

class _SessionCard extends StatelessWidget {
  final SessionLog log;
  const _SessionCard({required this.log});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _showDetail(context),
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
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.videocam_outlined,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDateTime(log.startedAt), style: AppTextStyles.label),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(log.formattedDuration, style: AppTextStyles.caption),
                    if (log.rating != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < log.rating! ? Icons.star : Icons.star_border,
                            color: AppColors.warning,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey400),
        ],
      ),
    ),
  );

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text('Session Details', style: AppTextStyles.h2),
            const SizedBox(height: Spacing.md),
            _DetailRow('Date', formatDateTime(log.startedAt)),
            _DetailRow('Duration', log.formattedDuration),
            if (log.rating != null) _DetailRow('Rating', '⭐' * log.rating!),
            if (log.memberNotes != null)
              _DetailRow('Your Notes', log.memberNotes!),
            if (log.trainerNotes != null)
              _DetailRow('Trainer Notes', log.trainerNotes!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    ),
  );
}
