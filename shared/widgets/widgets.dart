// ============================================================
// Shared Widgets — WTF Flutter Assessment
// ============================================================

import 'package:flutter/material.dart';
import '../utils/utils.dart';
import '../models/models.dart';
import '../services/services.dart';

// ── Role Badge ────────────────────────────────────────────────
class RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const RoleBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

// ── Avatar ────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;
  final Color? fallbackColor;

  const UserAvatar({
    super.key,
    required this.url,
    required this.name,
    this.radius = 20,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url!),
        backgroundColor: AppColors.grey200,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackColor ?? AppColors.memberPrimary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

// ── Loading Skeleton ──────────────────────────────────────────
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.grey200.withValues(alpha: _anim.value),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    ),
  );
}

// ── Empty State ────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(icon, size: 40, color: AppColors.grey400),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            title,
            style: AppTextStyles.h3.copyWith(color: AppColors.grey700),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: Spacing.lg),
            FilledButton(onPressed: onCta, child: Text(ctaLabel!)),
          ],
        ],
      ),
    ),
  );
}

// ── Typing Indicator ──────────────────────────────────────────
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 200)),
    );
    _animations = _controllers
        .map(
          (c) => Tween(
            begin: 0.0,
            end: -6.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.grey200,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _animations[i].value),
            child: Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: AppColors.grey500,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ── Status Ticks ──────────────────────────────────────────────
class StatusTicks extends StatelessWidget {
  final MessageStatus status;
  final Color color;

  const StatusTicks({super.key, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    if (status == MessageStatus.sending) {
      return Icon(
        Icons.access_time,
        size: 12,
        color: color.withValues(alpha: 0.6),
      );
    }
    if (status == MessageStatus.sent) {
      return Icon(Icons.check, size: 14, color: color.withValues(alpha: 0.7));
    }
    // read
    return Stack(
      children: [
        Icon(Icons.check, size: 14, color: color),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Icon(Icons.check, size: 14, color: color),
        ),
      ],
    );
  }
}

// ── Dev Panel ─────────────────────────────────────────────────
class DevPanel extends StatefulWidget {
  final String appName;
  final String version;

  const DevPanel({super.key, required this.appName, required this.version});

  @override
  State<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<DevPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (_open)
        Positioned(
          right: 16,
          bottom: 80,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bug_report,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.appName} v${widget.version}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _open = false),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: StreamBuilder<List<LogEntry>>(
                      stream: AppLogger.stream,
                      initialData: AppLogger.entries,
                      builder: (_, snapshot) {
                        final logs = (snapshot.data ?? []).reversed
                            .take(20)
                            .toList();
                        if (logs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No logs yet',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: logs.length,
                          itemBuilder: (_, i) {
                            final e = logs[i];
                            final tagColor = _tagColor(e.tag);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '[${e.tag.name.toUpperCase()}] ',
                                      style: TextStyle(color: tagColor),
                                    ),
                                    TextSpan(
                                      text: e.message,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      Positioned(
        right: 16,
        bottom: 24,
        child: FloatingActionButton.small(
          heroTag: 'devpanel',
          onPressed: () => setState(() => _open = !_open),
          backgroundColor: AppColors.grey800,
          child: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ),
    ],
  );

  Color _tagColor(LogTag tag) => switch (tag) {
    LogTag.chat => Colors.blue,
    LogTag.rtc => Colors.orange,
    LogTag.schedule => Colors.purple,
    LogTag.auth => Colors.green,
    LogTag.general => Colors.white54,
  };
}

// ── Star Rating ───────────────────────────────────────────────
class StarRating extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const StarRating({super.key, required this.value, required this.onChanged});

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (i) => GestureDetector(
        onTap: () => widget.onChanged(i + 1),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            i < widget.value ? Icons.star : Icons.star_border,
            key: ValueKey('star_${i}_${widget.value}'),
            color: AppColors.warning,
            size: 32,
          ),
        ),
      ),
    ),
  );
}
