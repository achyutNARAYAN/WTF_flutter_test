// ============================================================
// Requests Screen — Guru App
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'package:wtf_shared/widgets/widgets.dart';
import 'providers.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Scaffold();

    final requestsAsync = ref.watch(memberRequestsProvider(user.id));
    final requests = requestsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/home/schedule'),
          ),
        ],
      ),
      body: requests.isEmpty
          ? EmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No requests yet',
              subtitle: 'Schedule your first call with Aarav.',
              ctaLabel: 'Schedule Now',
              onCta: () => context.go('/home/schedule'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _RequestCard(request: requests[i]),
            ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final CallRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isJoinable =
        request.status == CallRequestStatus.approved &&
        request.scheduledFor
            .subtract(const Duration(minutes: 10))
            .isBefore(DateTime.now());

    final statusColor = switch (request.status) {
      CallRequestStatus.pending => AppColors.warning,
      CallRequestStatus.approved => AppColors.success,
      CallRequestStatus.declined => AppColors.error,
      CallRequestStatus.cancelled => AppColors.grey400,
    };

    final statusLabel = switch (request.status) {
      CallRequestStatus.pending => '⏳ Pending approval by Aarav',
      CallRequestStatus.approved => '✅ Approved',
      CallRequestStatus.declined => '❌ Declined',
      CallRequestStatus.cancelled => '🚫 Cancelled',
    };

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatDateTime(request.scheduledFor),
                  style: AppTextStyles.label,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
          ),
          if (request.note != null) ...[
            const SizedBox(height: 6),
            Text(
              '"${request.note}"',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (request.status == CallRequestStatus.declined &&
              request.declineReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${request.declineReason}',
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          if (isJoinable) ...[
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/home/call/${request.id}'),
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Join Call'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
