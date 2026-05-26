// ============================================================
// Call Screen (100ms Integration) — Guru App
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/services/services.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'package:wtf_shared/widgets/widgets.dart';
import 'providers.dart';

// ── Pre-Join Screen ───────────────────────────────────────────
class CallScreen extends ConsumerStatefulWidget {
  final String requestId;
  const CallScreen({super.key, required this.requestId});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  bool _micOn = true;
  bool _camOn = true;
  bool _joined = false;
  bool _loading = false;
  DateTime? _callStart;
  Timer? _durationTimer;
  int _durationSec = 0;

  // 100ms SDK
  HMSSDK? _hmsSDK;
  HMSVideoTrack? _localVideoTrack;
  HMSVideoTrack? _remoteVideoTrack;
  bool _remoteJoined = false;
  bool _reconnecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSDK();
  }

  Future<void> _initSDK() async {
    _hmsSDK = HMSSDK();
    await _hmsSDK!.build();
    AppLogger.log(LogTag.rtc, 'HMS SDK initialized');
  }

  Future<bool> _requestPermissions() async {
    try {
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      final cameraGranted = cameraStatus.isGranted;
      final micGranted = micStatus.isGranted;

      if (cameraGranted && micGranted) {
        AppLogger.log(LogTag.rtc, 'Camera and microphone permissions granted');
        return true;
      } else {
        AppLogger.log(LogTag.rtc, 'Camera or microphone permissions denied');
        if (mounted) {
          setState(() {
            _error =
                'Camera and microphone permissions are required for calls.';
          });
        }
        return false;
      }
    } catch (e) {
      AppLogger.log(LogTag.rtc, 'Permission request failed', error: e);
      return false;
    }
  }

  Future<void> _join(User user, RoomMeta room) async {
    // Request permissions first
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    AppLogger.log(LogTag.rtc, 'Joining room ${room.hmsRoomId}');

    try {
      final tokenSvc = ref.read(hmsTokenServiceProvider);
      final token = await tokenSvc.getToken(
        userId: user.id,
        role: user.role.name,
        roomId: room.hmsRoomId,
      );

      // Initialize with mic/camera state from pre-join screen
      final config = HMSConfig(
        authToken: token,
        userName: user.name,
        captureNetworkQualityInPreview: true,
      );

      _hmsSDK!.addUpdateListener(
        listener: _HMSListener(
          onJoin: () {
            if (mounted) {
              setState(() {
                _joined = true;
                _loading = false;
              });
            }
            _startTimer();
            AppLogger.log(LogTag.rtc, 'Joined room successfully');
          },
          onVideoTrack: (track, isLocal) {
            if (mounted) {
              setState(() {
                if (isLocal) {
                  _localVideoTrack = track;
                } else {
                  _remoteVideoTrack = track;
                  _remoteJoined = true;
                }
              });
            }
          },
          onPeerLeft: () {
            if (mounted) setState(() => _remoteJoined = false);
          },
          onReconnecting: () {
            if (mounted) setState(() => _reconnecting = true);
            AppLogger.log(LogTag.rtc, 'Reconnecting...');
          },
          onReconnected: () {
            if (mounted) setState(() => _reconnecting = false);
            AppLogger.log(LogTag.rtc, 'Reconnected');
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _error = error;
                _loading = false;
              });
            }
            AppLogger.log(LogTag.rtc, 'HMS error: $error', error: error);
          },
        ),
      );

      await _hmsSDK!.join(config: config);

      // Apply initial mic/camera settings after joining
      if (!_micOn) {
        try {
          await _hmsSDK?.toggleMicMuteState();
          AppLogger.log(LogTag.rtc, 'Microphone muted');
        } catch (e) {
          AppLogger.log(LogTag.rtc, 'Failed to mute microphone', error: e);
        }
      }

      if (!_camOn) {
        try {
          await _hmsSDK?.toggleCameraMuteState();
          AppLogger.log(LogTag.rtc, 'Camera muted');
        } catch (e) {
          AppLogger.log(LogTag.rtc, 'Failed to mute camera', error: e);
        }
      }
    } catch (e) {
      AppLogger.log(LogTag.rtc, 'Join failed', error: e);
      // Graceful mock fallback for demo
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _joined = true;
          _loading = false;
          _remoteJoined = true; // Simulate peer joined
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _callStart = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _durationSec++);
    });
  }

  Future<void> _endCall(User user) async {
    _durationTimer?.cancel();
    final end = DateTime.now();
    final start = _callStart ?? end;

    try {
      await _hmsSDK?.leave();
    } catch (_) {}

    AppLogger.log(
      LogTag.rtc,
      'Call ended. Duration: ${end.difference(start).inSeconds}s',
    );

    // Create session log
    final logSvc = ref.read(logServiceProvider);
    final log = logSvc.createLog(
      memberId: user.id,
      trainerId: user.assignedTrainerId ?? SeedData.trainer.id,
      startedAt: start,
      endedAt: end,
    );

    if (mounted) {
      _showPostCallSheet(log, user);
    }
  }

  void _showPostCallSheet(SessionLog log, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _PostCallSheet(
        log: log,
        onDone: (rating, notes) {
          ref
              .read(logServiceProvider)
              .updateMemberNotes(log.id, rating, notes!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session saved to your logs.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/home/sessions');
        },
      ),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _hmsSDK?.leave();
    _hmsSDK?.destroy();
    super.dispose();
  }

  String get _durationLabel {
    final m = _durationSec ~/ 60;
    final s = _durationSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Scaffold();

    final callSvc = ref.read(callServiceProvider);
    final room = callSvc.getRoomForRequest(widget.requestId);

    if (!_joined) {
      return _PreJoinScreen(
        user: user,
        micOn: _micOn,
        camOn: _camOn,
        loading: _loading,
        error: _error,
        onMicToggle: () => setState(() => _micOn = !_micOn),
        onCamToggle: () => setState(() => _camOn = !_camOn),
        onJoin: () {
          if (room != null) {
            _join(user, room);
          } else {
            // Demo fallback: mock join
            setState(() {
              _loading = true;
            });
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _joined = true;
                  _loading = false;
                  _remoteJoined = true;
                });
                _startTimer();
              }
            });
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          _VideoTile(
            label: SeedData.trainer.name,
            isLocal: false,
            track: _remoteVideoTrack,
            joined: _remoteJoined,
          ),

          // Local video (PiP)
          Positioned(
            top: 60,
            right: 16,
            child: SizedBox(
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _VideoTile(
                  label: user.name,
                  isLocal: true,
                  track: _localVideoTrack,
                  joined: true,
                  small: true,
                ),
              ),
            ),
          ),

          // Reconnecting overlay
          if (_reconnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Reconnecting…',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 8,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _durationLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Controls bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CtrlButton(
                      icon: _micOn ? Icons.mic : Icons.mic_off,
                      label: _micOn ? 'Mute' : 'Unmute',
                      active: _micOn,
                      onTap: () async {
                        try {
                          await _hmsSDK?.toggleMicMuteState();
                          if (mounted) {
                            setState(() => _micOn = !_micOn);
                          }
                        } catch (e) {
                          AppLogger.log(
                            LogTag.rtc,
                            'Failed to toggle mic',
                            error: e,
                          );
                        }
                      },
                    ),
                    _CtrlButton(
                      icon: _camOn ? Icons.videocam : Icons.videocam_off,
                      label: _camOn ? 'Stop Video' : 'Start Video',
                      active: _camOn,
                      onTap: () async {
                        try {
                          await _hmsSDK?.toggleCameraMuteState();
                          if (mounted) {
                            setState(() => _camOn = !_camOn);
                          }
                        } catch (e) {
                          AppLogger.log(
                            LogTag.rtc,
                            'Failed to toggle camera',
                            error: e,
                          );
                        }
                      },
                    ),
                    _CtrlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'Flip',
                      active: true,
                      onTap: () => _hmsSDK?.switchCamera(),
                    ),
                    _CtrlButton(
                      icon: Icons.call_end,
                      label: 'End',
                      active: false,
                      color: AppColors.error,
                      onTap: () => _endCall(user),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final String label;
  final bool isLocal;
  final HMSVideoTrack? track;
  final bool joined;
  final bool small;

  const _VideoTile({
    required this.label,
    required this.isLocal,
    required this.track,
    required this.joined,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!joined) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white54),
              const SizedBox(height: 12),
              Text(
                'Waiting for $label…',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    Widget videoWidget;
    if (track != null) {
      videoWidget = HMSVideoView(track: track!);
    } else {
      // Camera off or not available
      videoWidget = Container(
        color: const Color(0xFF2A2A3E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: small ? 20 : 40,
                backgroundColor: Colors.white24,
                child: Text(
                  label[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: small ? 16 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!small) ...[
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: videoWidget),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: small ? 10 : 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  const _CtrlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color:
                color ??
                (active ? Colors.white24 : Colors.white.withValues(alpha: 0.1)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color != null
                ? Colors.white
                : (active ? Colors.white : Colors.white54),
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );
}

// ── Pre-Join Screen ───────────────────────────────────────────
class _PreJoinScreen extends StatelessWidget {
  final User user;
  final bool micOn;
  final bool camOn;
  final bool loading;
  final String? error;
  final VoidCallback onMicToggle;
  final VoidCallback onCamToggle;
  final VoidCallback onJoin;

  const _PreJoinScreen({
    required this.user,
    required this.micOn,
    required this.camOn,
    required this.loading,
    required this.error,
    required this.onMicToggle,
    required this.onCamToggle,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/home/requests'),
      ),
      title: const Text(
        'Ready to join?',
        style: TextStyle(color: Colors.white),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          children: [
            const SizedBox(height: Spacing.xl),

            // Camera preview mock
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.memberPrimary,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready to join? Check mic and camera.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // Toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DeviceToggle(
                  icon: micOn ? Icons.mic : Icons.mic_off,
                  label: 'Mic',
                  active: micOn,
                  onTap: onMicToggle,
                ),
                const SizedBox(width: 24),
                _DeviceToggle(
                  icon: camOn ? Icons.videocam : Icons.videocam_off,
                  label: 'Camera',
                  active: camOn,
                  onTap: onCamToggle,
                ),
              ],
            ),

            const Spacer(),

            if (error != null) ...[
              Text(
                error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
              const SizedBox(height: Spacing.sm),
            ],

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading ? null : onJoin,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.videocam),
                label: Text(loading ? 'Connecting…' : 'Join Call'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DeviceToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DeviceToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.15)
                : AppColors.error.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.white24 : AppColors.error,
            ),
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : AppColors.error,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

// ── Post-Call Sheet ───────────────────────────────────────────
class _PostCallSheet extends StatefulWidget {
  final SessionLog log;
  final void Function(int rating, String? notes) onDone;

  const _PostCallSheet({required this.log, required this.onDone});

  @override
  State<_PostCallSheet> createState() => _PostCallSheetState();
}

class _PostCallSheetState extends State<_PostCallSheet> {
  int _rating = 0;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: Spacing.sm),
        Text('Session Complete!', style: AppTextStyles.h2),
        Text(
          'Duration: ${widget.log.formattedDuration}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        const SizedBox(height: Spacing.lg),
        Text('Rate this session', style: AppTextStyles.label),
        const SizedBox(height: Spacing.sm),
        StarRating(
          value: _rating,
          onChanged: (r) => setState(() => _rating = r),
        ),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Add a note (optional)'),
        ),
        const SizedBox(height: Spacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _rating > 0
                ? () => widget.onDone(
                    _rating,
                    _notesController.text.isEmpty
                        ? null
                        : _notesController.text,
                  )
                : null,
            child: const Text('Save & Continue'),
          ),
        ),
      ],
    ),
  );
}

// ── HMS Listener Helper ───────────────────────────────────────
class _HMSListener implements HMSUpdateListener {
  final VoidCallback _onJoin;
  final void Function(HMSVideoTrack, bool) _onVideoTrack;
  final VoidCallback _onPeerLeft;
  final VoidCallback _onReconnecting;
  final VoidCallback _onReconnected;
  final void Function(String) _onError;

  _HMSListener({
    required VoidCallback onJoin,
    required void Function(HMSVideoTrack, bool) onVideoTrack,
    required VoidCallback onPeerLeft,
    required VoidCallback onReconnecting,
    required VoidCallback onReconnected,
    required void Function(String) onError,
  }) : _onJoin = onJoin,
       _onVideoTrack = onVideoTrack,
       _onPeerLeft = onPeerLeft,
       _onReconnecting = onReconnecting,
       _onReconnected = onReconnected,
       _onError = onError;

  @override
  void onJoin({required HMSRoom room}) => _onJoin();

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    if (update == HMSPeerUpdate.peerLeft) _onPeerLeft();
  }

  @override
  void onTrackUpdate({
    required HMSTrack track,
    required HMSTrackUpdate trackUpdate,
    required HMSPeer peer,
  }) {
    if (track is HMSVideoTrack) {
      _onVideoTrack(track, peer.isLocal);
    }
  }

  @override
  void onHMSError({required HMSException error}) =>
      _onError(error.message ?? 'Unknown error');

  @override
  void onReconnected() => _onReconnected();

  @override
  void onReconnecting() => _onReconnecting();

  // Required stubs
  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}
  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}
  @override
  void onAudioDeviceChanged({
    HMSAudioDevice? currentAudioDevice,
    List<HMSAudioDevice>? availableAudioDevice,
  }) {}
  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}
  @override
  void onPeerListUpdate({
    required List<HMSPeer> addedPeers,
    required List<HMSPeer> removedPeers,
  }) {}
  @override
  void onChangeTrackStateRequest({
    required HMSTrackChangeRequest hmsTrackChangeRequest,
  }) {}
  @override
  void onMessage({required HMSMessage message}) {}
  @override
  void onRemovedFromRoom({
    required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer,
  }) {}
  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}
}
