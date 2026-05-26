// ============================================================
// Onboarding Screen — Guru App
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/services/services.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  final _nameController = TextEditingController(text: 'DK');
  String? _selectedTrainerId;
  bool _loading = false;

  final _slides = [
    _Slide(
      emoji: '🏋️',
      title: 'Train with the best',
      body:
          'Get personalized coaching from certified fitness trainers — on your schedule.',
    ),
    _Slide(
      emoji: '📱',
      title: 'Chat. Schedule. Connect.',
      body:
          'Message your trainer, book video sessions, and track your progress — all in one place.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _showSetupSheet();
    }
  }

  void _showSetupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetupSheet(
        nameController: _nameController,
        selectedTrainerId: _selectedTrainerId,
        trainers: SeedData.trainers,
        onTrainerSelected: (id) => setState(() => _selectedTrainerId = id),
        onConfirm: _createProfile,
        loading: _loading,
      ),
    );
  }

  Future<void> _createProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    final trainerId = _selectedTrainerId ?? SeedData.trainers.first.id;
    setState(() => _loading = true);

    final authService = ref.read(authServiceProvider);
    await authService.completeMemberOnboarding(
      _nameController.text.trim(),
      trainerId,
    );
    AppLogger.log(
      LogTag.auth,
      'Member onboarding complete: ${_nameController.text}',
    );

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.memberPrimary,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (p) => setState(() => _page = p),
              itemCount: _slides.length,
              itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
            ),
          ),
          // Page dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _page == i ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _page == i
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.memberPrimary,
                ),
                child: Text(
                  _page < _slides.length - 1 ? 'Next' : 'Get Started',
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    ),
  );
}

class _Slide {
  final String emoji;
  final String title;
  final String body;
  const _Slide({required this.emoji, required this.title, required this.body});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Spacing.xl),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(slide.emoji, style: const TextStyle(fontSize: 80)),
        const SizedBox(height: Spacing.xl),
        Text(
          slide.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        Text(
          slide.body,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _SetupSheet extends StatelessWidget {
  final TextEditingController nameController;
  final String? selectedTrainerId;
  final List<User> trainers;
  final ValueChanged<String> onTrainerSelected;
  final VoidCallback onConfirm;
  final bool loading;

  const _SetupSheet({
    required this.nameController,
    required this.selectedTrainerId,
    required this.trainers,
    required this.onTrainerSelected,
    required this.onConfirm,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: EdgeInsets.only(
      left: Spacing.lg,
      right: Spacing.lg,
      top: Spacing.lg,
      bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
    ),
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
        const SizedBox(height: Spacing.lg),
        Text('Create your profile', style: AppTextStyles.h2),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text('Choose your trainer', style: AppTextStyles.label),
        const SizedBox(height: Spacing.sm),
        ...trainers.map(
          (t) => _TrainerTile(
            trainer: t,
            selected: selectedTrainerId == t.id,
            onTap: () => onTrainerSelected(t.id),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : onConfirm,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text("Let's go! 🚀"),
          ),
        ),
      ],
    ),
  );
}

class _TrainerTile extends StatelessWidget {
  final User trainer;
  final bool selected;
  final VoidCallback onTap;

  const _TrainerTile({
    required this.trainer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.memberPrimary.withValues(alpha: 0.08)
            : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.memberPrimary : AppColors.grey200,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.trainerPrimary,
            child: Text(
              trainer.name[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trainer.name, style: AppTextStyles.label),
              Text('Lead Trainer', style: AppTextStyles.caption),
            ],
          ),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_circle, color: AppColors.memberPrimary),
        ],
      ),
    ),
  );
}
