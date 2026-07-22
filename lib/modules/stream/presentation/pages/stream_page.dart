import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/stream/presentation/controllers/live_stream_controller.dart';

/// Full-screen live-streaming page.
///
/// Pass the active [MissionEntity] as `Get.arguments`.
///
/// Flow:
///   1. Page appears → calls [LiveStreamController.initialize].
///   2. Edge function returns LiveKit token → room connects → camera feed shown.
///   3. Scout taps "END MISSION" → confirmation dialog → mission marked
///      complete → [MissionCompletePage].
class StreamPage extends StatefulWidget {
  static const String route = '/stream';

  const StreamPage({super.key});

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  late final LiveStreamController _ctrl;
  late final MissionEntity _mission;

  @override
  void initState() {
    super.initState();
    // Force landscape-capable, portrait-primary — keep the video feed natural.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _mission = Get.arguments as MissionEntity;
    _ctrl = Get.find<LiveStreamController>();
    _ctrl.mission = _mission;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ctrl.initialize(_mission),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera feed — fills the whole screen.
          _CameraFeed(ctrl: _ctrl),

          // 2. Top overlay — live badge, scout name, timer.
          _TopOverlay(ctrl: _ctrl),

          // 3. Bottom gradient + scout info + controls.
          _BottomSection(ctrl: _ctrl, mission: _mission),
        ],
      ),
    );
  }
}

// ── Camera feed ───────────────────────────────────────────────────────────────

class _CameraFeed extends StatelessWidget {
  final LiveStreamController ctrl;
  const _CameraFeed({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Connecting ────────────────────────────────────────────────────────
      if (ctrl.isConnecting.value) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: ClientColors.primary,
                  strokeWidth: 2,
                ),
                16.verticalSpace,
                Text(
                  'Starting stream…',
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // ── Error ─────────────────────────────────────────────────────────────
      if (ctrl.hasError.value) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  color: ClientColors.green,
                  size: 52,
                ),
                20.verticalSpace,
                Text(
                  'Failed to start stream.',
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                4.verticalSpace,
                Text(
                  'Check your connection and try again.',
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                24.verticalSpace,
                TextButton(
                  onPressed: Get.back,
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      color: ClientColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // ── Live — render camera track ─────────────────────────────────────────
      final track = ctrl.videoTrack.value;
      if (track != null) {
        return SizedBox.expand(
          child: VideoTrackRenderer(track, fit: VideoViewFit.cover),
        );
      }

      // Camera track not yet published — black placeholder.
      return const ColoredBox(color: Colors.black);
    });
  }
}

// ── Top overlay ───────────────────────────────────────────────────────────────

class _TopOverlay extends StatelessWidget {
  final LiveStreamController ctrl;
  const _TopOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: live info ──────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Live Feed',
                  style: TextStyle(
                    color: ClientColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                8.verticalSpace,
                const _LiveBadge(),
                6.verticalSpace,
                Obx(() => _ClientStatusText(state: ctrl.clientState.value)),
              ],
            ),

            const Spacer(),

            // ── Right: timer + ending-soon hint ──────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => _TimerBadge(
                    label: ctrl.timerLabel,
                    exceeded: ctrl.isExceeded.value,
                  ),
                ),
                Builder(
                  builder: (_) {
                    final warning = ctrl.endingSoonLabel;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: warning == null
                          ? const SizedBox.shrink()
                          : Padding(
                              key: ValueKey(warning),
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                warning,
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom gradient + controls ────────────────────────────────────────────────

class _BottomSection extends StatelessWidget {
  final LiveStreamController ctrl;
  final MissionEntity mission;
  const _BottomSection({required this.ctrl, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xCC000000), Colors.black],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Scout info row ───────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ScoutAvatar(ctrl: ctrl),
                    14.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctrl.mission.client?.displayName ?? 'Viewer',
                            style: TextStyle(
                              color: ClientColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          6.verticalSpace,
                          _GpsBadge(address: mission.address),
                        ],
                      ),
                    ),
                    16.horizontalSpace,
                    _MicButton(ctrl: ctrl),
                  ],
                ),

                22.verticalSpace,

                // ── End Mission button ───────────────────────────────────────
                _EndMissionButton(ctrl: ctrl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Live badge ────────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFCC1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          _PulsingDot(),
          SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing dot inside the LIVE badge ─────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Timer badge ───────────────────────────────────────────────────────────────

/// Timer pill — turns red and pulses when the mission duration is exceeded.
class _TimerBadge extends StatefulWidget {
  final String label;
  final bool exceeded;
  const _TimerBadge({required this.label, required this.exceeded});

  @override
  State<_TimerBadge> createState() => _TimerBadgeState();
}

class _TimerBadgeState extends State<_TimerBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.exceeded) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TimerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exceeded && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.exceeded && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exceededColor = const Color(0xFFCC1E1E);
    final baseColor = const Color(0xFF111827);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final bg = widget.exceeded
            ? Color.lerp(exceededColor, Colors.white, _pulse.value * 0.2)!
            : baseColor;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.exceeded
                  ? Colors.white.withAlpha(80)
                  : Colors.white12,
            ),
            boxShadow: widget.exceeded
                ? [
                    BoxShadow(
                      color: exceededColor.withAlpha(
                        (120 + 80 * _pulse.value).toInt(),
                      ),
                      blurRadius: 14 + 6 * _pulse.value,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.exceeded
                ? Icons.warning_amber_rounded
                : Icons.timer_outlined,
            color: widget.exceeded ? Colors.white : const Color(0xFFFFD700),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Client status text (shown under the LIVE badge) ───────────────────────────

class _ClientStatusText extends StatelessWidget {
  final ClientStreamState state;
  const _ClientStatusText({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      ClientStreamState.waiting => (
        'Waiting for viewer to join…',
        ClientColors.textSecondary,
      ),
      ClientStreamState.joined => ('Viewer is watching', ClientColors.primary),
      ClientStreamState.disconnected => (
        'Viewer disconnected — reconnecting…',
        Color(0xFFF5A020),
      ),
      ClientStreamState.droppedOff => (
        'Viewer left the stream',
        Color(0xFFF5A020),
      ),
      ClientStreamState.terminated => (
        'Stream ended',
        ClientColors.textSecondary,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        label,
        key: ValueKey(label),
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

// ── Scout avatar ──────────────────────────────────────────────────────────────

class _ScoutAvatar extends StatelessWidget {
  final LiveStreamController ctrl;
  const _ScoutAvatar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final name = ctrl.mission.client?.displayName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    return Obx(() {
      final state = ctrl.clientState.value;
      final ringColor = switch (state) {
        ClientStreamState.joined => ClientColors.primary,
        ClientStreamState.waiting => ClientColors.textSecondary,
        ClientStreamState.disconnected ||
        ClientStreamState.droppedOff => const Color(0xFFF5A020),
        ClientStreamState.terminated => Colors.white24,
      };
      final micMuted = ctrl.clientMicMuted.value;

      return SizedBox(
        width: 58,
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2.5),
              ),
              child: ClipOval(
                child: Container(
                  color: ClientColors.surface,
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Mic-muted badge on the client's avatar ────────────────────────
            if (micMuted)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFCC1E1E),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(
                    Icons.mic_off,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── GPS location badge ────────────────────────────────────────────────────────

class _GpsBadge extends StatelessWidget {
  final String address;
  const _GpsBadge({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_pin, color: Colors.redAccent, size: 13),
          const SizedBox(width: 4),
          Text(
            'GPS ✓ ',
            style: TextStyle(
              color: ClientColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Flexible(
            child: Text(
              address.isNotEmpty ? address : 'On Location',
              style: TextStyle(color: ClientColors.primary, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Microphone toggle button ──────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final LiveStreamController ctrl;
  const _MicButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => GestureDetector(
            onTap: ctrl.toggleMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ctrl.isMicEnabled.value
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFCC1E1E),
              ),
              child: Icon(
                ctrl.isMicEnabled.value ? Icons.mic : Icons.mic_off,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        4.verticalSpace,
        const Text(
          'MIC',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── End Mission button ────────────────────────────────────────────────────────

class _EndMissionButton extends StatelessWidget {
  final LiveStreamController ctrl;
  const _EndMissionButton({required this.ctrl});

  void _confirm() {
    Get.dialog(
      AlertDialog(
        backgroundColor: ClientColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'End Live Check?',
          style: TextStyle(
            color: ClientColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will stop your stream and mark the live check as complete.',
          style: TextStyle(
            color: ClientColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'Cancel',
              style: TextStyle(color: ClientColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.endMission();
            },
            child: const Text(
              'End Live Check',
              style: TextStyle(
                color: Color(0xFFCC1E1E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ElevatedButton.icon(
        onPressed: ctrl.isEndingMission.value ? null : _confirm,
        icon: ctrl.isEndingMission.value
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.close_rounded, size: 18),
        label: Text(
          ctrl.isEndingMission.value ? 'Ending…' : 'END LIVE CHECK',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCC1E1E),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCC1E1E).withAlpha(150),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
