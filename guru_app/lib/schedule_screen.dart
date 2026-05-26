// ============================================================
// Schedule Screen — Guru App
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/services/services.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'providers.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime? _selectedDay;
  DateTime? _selectedSlot;
  final _noteController = TextEditingController();
  bool _loading = false;
  String? _error;

  final _days = List.generate(3, (i) => DateTime.now().add(Duration(days: i)));

  List<DateTime> _slotsFor(DateTime day) {
    final slots = <DateTime>[];
    for (var h = 8; h <= 20; h++) {
      slots.add(DateTime(day.year, day.month, day.day, h, 0));
      slots.add(DateTime(day.year, day.month, day.day, h, 30));
    }
    return slots.where((s) => s.isAfter(DateTime.now())).toList();
  }

  Future<void> _request(User user) async {
    if (_selectedSlot == null) {
      setState(() => _error = 'Please select a time slot');
      return;
    }

    final callSvc = ref.read(callServiceProvider);
    final trainerId = user.assignedTrainerId ?? SeedData.trainer.id;

    // Conflict check
    if (callSvc.hasConflict(trainerId, _selectedSlot!)) {
      setState(() => _error = 'This slot is already booked. Choose another.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    AppLogger.log(LogTag.schedule, 'Creating call request for $_selectedSlot');

    callSvc.createRequest(
      memberId: user.id,
      trainerId: trainerId,
      scheduledFor: _selectedSlot!,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call requested. Waiting for trainer approval.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home/requests');
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Scaffold();

    final dayLabels = ['Today', 'Tomorrow', _formatDay(_days[2])];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule a Call'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day selector
            Text('Select day', style: AppTextStyles.h3),
            const SizedBox(height: Spacing.sm),
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedDay = _days[i];
                      _selectedSlot = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedDay?.day == _days[i].day
                            ? AppColors.memberPrimary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDay?.day == _days[i].day
                              ? AppColors.memberPrimary
                              : AppColors.grey300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayLabels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedDay?.day == _days[i].day
                                  ? Colors.white
                                  : AppColors.grey800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_days[i].day}/${_days[i].month}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedDay?.day == _days[i].day
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Time slots
            if (_selectedDay != null) ...[
              const SizedBox(height: Spacing.lg),
              Text('Select time (30-min blocks)', style: AppTextStyles.h3),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slotsFor(_selectedDay!).map((slot) {
                  final selected = _selectedSlot == slot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSlot = slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.memberPrimary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.memberPrimary
                              : AppColors.grey300,
                        ),
                      ),
                      child: Text(
                        _formatSlot(slot),
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.grey800,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: Spacing.lg),
            Text('Note (optional)', style: AppTextStyles.h3),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _noteController,
              maxLength: 140,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What would you like to work on?',
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ],

            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : () => _request(user),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Request Call'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDay(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }

  String _formatSlot(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}
