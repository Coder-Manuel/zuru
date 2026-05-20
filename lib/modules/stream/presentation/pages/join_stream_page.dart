import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/stream/presentation/controllers/join_stream_controller.dart';

/// Full-screen viewer page — client watches a scout's live stream.
///
/// Pass the active [MissionEntity] as `Get.arguments`.
class JoinStreamPage extends StatefulWidget {
  static const String route = '/join-stream';
  const JoinStreamPage({super.key});

  @override
  State<JoinStreamPage> createState() => _JoinStreamPageState();
}

class _JoinStreamPageState extends State<JoinStreamPage> {
  late final JoinStreamController _ctrl;
  late final MissionEntity _mission;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _mission = Get.arguments as MissionEntity;
    _ctrl = Get.find<JoinStreamController>();
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
          _RemoteFeed(ctrl: _ctrl),
          _TopOverlay(ctrl: _ctrl),
          _BottomSection(ctrl: _ctrl, mission: _mission),
        ],
      ),
    );
  }
}

// ─── Remote feed ─────────────────────────────────────────────────────────────

class _RemoteFeed extends StatelessWidget {
  final JoinStreamController ctrl;
  const _RemoteFeed({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Connecting ──────────────────────────────────────────────────────
      if (ctrl.isConnecting.value) {
        return _FullScreenMessage(
          icon: null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: ClientColors.primary,
                strokeWidth: 2,
              ),
              16.verticalSpace,
              Text(
                'Joining stream…',
                style: TextStyle(color: ClientColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        );
      }

      // ── Error ───────────────────────────────────────────────────────────
      if (ctrl.hasError.value) {
        return _FullScreenMessage(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                color: ClientColors.primary,
                size: 52,
              ),
              20.verticalSpace,
              Text(
                'Failed to join stream.',
                style: TextStyle(color: ClientColors.textSecondary, fontSize: 15),
              ),
              4.verticalSpace,
              Text(
                'Check your connection and try again.',
                style: TextStyle(color: ClientColors.textSecondary, fontSize: 13),
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
        );
      }

      // ── Disconnected ────────────────────────────────────────────────────
      if (ctrl.scoutStatus.value == ScoutStatus.disconnected) {
        return _FullScreenMessage(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withAlpha(30),
                ),
                child: const Icon(
                  Icons.signal_wifi_connected_no_internet_4_rounded,
                  color: Colors.grey,
                  size: 42,
                ),
              ),
              20.verticalSpace,
              const Text(
                'Scout disconnected',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              8.verticalSpace,
              const Text(
                'Ending session…',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        );
      }

      // ── Video track available ───────────────────────────────────────────
      final track = ctrl.remoteVideoTrack.value;
      if (track != null) {
        return SizedBox.expand(
          child: VideoTrackRenderer(track, fit: VideoViewFit.cover),
        );
      }

      // ── Waiting for scout to start ──────────────────────────────────────
      return _FullScreenMessage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingIcon(),
            16.verticalSpace,
            Text(
              'Waiting for scout to stream…',
              style: TextStyle(color: ClientColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Top overlay ─────────────────────────────────────────────────────────────

class _TopOverlay extends StatelessWidget {
  final JoinStreamController ctrl;
  const _TopOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: scout status badge ───────────────────────────────
                Obx(() => _StatusBadge(status: ctrl.scoutStatus.value)),

                const Spacer(),

                // ── Right: countdown timer ─────────────────────────────────
                Obx(() {
                  final endingSoon = ctrl.endingSoonLabel;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TimerBadge(
                        label: ctrl.timerLabel,
                        isWarning: endingSoon != null,
                        isExpired: ctrl.isExceeded.value,
                      ),
                      if (endingSoon != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          endingSoon,
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),

            // ── Reconnecting pill (local user lost connection) ─────────────
            Obx(() {
              if (!ctrl.isReconnecting.value) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _EventPill(
                  icon: Icons.wifi_off_rounded,
                  label: 'Reconnecting…',
                  color: const Color(0xFFFBBF24),
                  persistent: true,
                ),
              );
            }),

            // ── Participant event toast (scout joined / disconnected / etc.) ─
            Obx(() {
              final event = ctrl.participantEvent.value;
              if (event == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _EventPill(label: event),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom section ───────────────────────────────────────────────────────────

class _BottomSection extends StatelessWidget {
  final JoinStreamController ctrl;
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
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Scout info row ───────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Scout avatar with dynamic status ring
                    Obx(
                      () => _ScoutAvatar(
                        name: ctrl.mission.scout?.displayName ?? 'Scout',
                        status: ctrl.scoutStatus.value,
                      ),
                    ),
                    14.horizontalSpace,
                    // Name + GPS badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctrl.mission.scout?.displayName ?? 'Scout',
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
                    14.horizontalSpace,
                    // Mic toggle button
                    Obx(
                      () => _MicButton(
                        enabled: ctrl.isMicEnabled.value,
                        onTap: ctrl.toggleMic,
                      ),
                    ),
                  ],
                ),

                22.verticalSpace,

                // ── Leave stream button ──────────────────────────────────
                _LeaveStreamButton(onTap: ctrl.leaveStream),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ScoutStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ScoutStatus.streaming => _badge(
        color: const Color(0xFF3B82F6),
        dot: true,
        label: 'WATCHING',
      ),
      ScoutStatus.waiting => _badge(
        color: ClientColors.primary,
        dot: true,
        label: 'WAITING',
      ),
      ScoutStatus.muted => _badge(
        color: const Color(0xFFEF4444),
        dot: false,
        label: 'SCOUT MUTED',
        icon: Icons.mic_off_rounded,
      ),
      ScoutStatus.disconnected => _badge(
        color: Colors.grey,
        dot: false,
        label: 'DISCONNECTED',
        icon: Icons.wifi_off_rounded,
      ),
    };
  }

  Widget _badge({
    required Color color,
    required String label,
    bool dot = false,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[_PulsingDot(color: color), const SizedBox(width: 6)],
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timer badge ─────────────────────────────────────────────────────────────

class _TimerBadge extends StatefulWidget {
  final String label;
  final bool isWarning;
  final bool isExpired;

  const _TimerBadge({
    required this.label,
    required this.isWarning,
    required this.isExpired,
  });

  @override
  State<_TimerBadge> createState() => _TimerBadgeState();
}

class _TimerBadgeState extends State<_TimerBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_TimerBadge old) {
    super.didUpdateWidget(old);
    // Start pulsing when warning or expired; stop otherwise.
    final shouldPulse = widget.isWarning || widget.isExpired;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _bgColor {
    if (widget.isExpired) return const Color(0xFF450A0A);
    if (widget.isWarning) return const Color(0xFF2D1D00);
    return const Color(0xFF111827);
  }

  Color get _borderColor {
    if (widget.isExpired) return const Color(0xFFEF4444);
    if (widget.isWarning) return const Color(0xFFFBBF24);
    return Colors.white12;
  }

  Color get _iconColor {
    if (widget.isExpired) return const Color(0xFFEF4444);
    if (widget.isWarning) return const Color(0xFFFBBF24);
    return const Color(0xFFFFD700);
  }

  Color get _textColor {
    if (widget.isExpired) return const Color(0xFFEF4444);
    if (widget.isWarning) return const Color(0xFFFBBF24);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, color: _iconColor, size: 16),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scout avatar with status ring ───────────────────────────────────────────

class _ScoutAvatar extends StatefulWidget {
  final String name;
  final ScoutStatus status;

  const _ScoutAvatar({required this.name, required this.status});

  @override
  State<_ScoutAvatar> createState() => _ScoutAvatarState();
}

class _ScoutAvatarState extends State<_ScoutAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ringOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(_ring);
    _updateAnimation();
  }

  @override
  void didUpdateWidget(_ScoutAvatar old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.status == ScoutStatus.waiting) {
      _ring.repeat(reverse: true);
    } else {
      _ring.stop();
      _ring.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  Color get _ringColor => switch (widget.status) {
    ScoutStatus.waiting => ClientColors.primary,
    ScoutStatus.streaming => const Color(0xFF3B82F6),
    ScoutStatus.muted => const Color(0xFFEF4444),
    ScoutStatus.disconnected => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'S';

    return AnimatedBuilder(
      animation: _ringOpacity,
      builder: (_, child) => Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _ringColor.withAlpha((255 * _ringOpacity.value).round()),
            width: 2.5,
          ),
        ),
        child: child,
      ),
      child: ClipOval(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.status == ScoutStatus.disconnected ? 0.4 : 1.0,
          child: Container(
            color: ClientColors.surface,
            alignment: Alignment.center,
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
    );
  }
}

// ─── GPS location badge ───────────────────────────────────────────────────────

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

// ─── Mic toggle button ────────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _MicButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = enabled
        ? const Color(0xFF374151) // grey when mic is on
        : const Color(0xFF3B0000); // dark red when muted
    final iconColor = enabled ? Colors.white : const Color(0xFFEF4444);
    final labelColor = enabled ? Colors.white70 : const Color(0xFFEF4444);
    final icon = enabled ? Icons.mic_rounded : Icons.mic_off_rounded;
    final label = enabled ? 'MIC' : 'MUTED';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          6.verticalSpace,
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Leave stream button ──────────────────────────────────────────────────────

class _LeaveStreamButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LeaveStreamButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text(
        'LEAVE STREAM',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }
}

// ─── Full-screen centred message ──────────────────────────────────────────────

class _FullScreenMessage extends StatelessWidget {
  final Widget child;
  final Widget? icon; // unused param kept for positional compatibility
  const _FullScreenMessage({required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(child: child),
    );
  }
}

// ─── Pulsing dot ─────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

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
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}

// ─── Pulsing camera icon for "waiting" feed placeholder ──────────────────────

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.8).animate(_ctrl);
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
      child: Icon(
        Icons.videocam_outlined,
        color: ClientColors.primary,
        size: 52,
      ),
    );
  }
}

// ─── Event pill ───────────────────────────────────────────────────────────────
///
/// A small translucent pill shown when a participant connects or disconnects,
/// and when the local client is reconnecting. Slides down and fades in on
/// appearance. Persistent pills stay until the Obx removes them.

class _EventPill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;

  /// When true the pill does not rely on auto-removal — it stays until the
  /// observable driving the Obx is cleared externally.
  final bool persistent;

  const _EventPill({
    required this.label,
    this.icon,
    this.color = Colors.white70,
    this.persistent = false,
  });

  @override
  State<_EventPill> createState() => _EventPillState();
}

class _EventPillState extends State<_EventPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(160),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withAlpha(60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.color, size: 13),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
