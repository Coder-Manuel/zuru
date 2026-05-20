import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/services/location_service/location_service.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/stream/presentation/pages/stream_page.dart';

// ── Verification states ───────────────────────────────────────────────────────

enum _GpsState { locating, verified, tooFar }

/// GPS proximity check shown after the Mapbox navigation session ends.
///
/// Pass the target [MissionEntity] as `Get.arguments`.
///
/// Flow:
///   1. **Locating** — progress bar animates while the device GPS fix settles.
///   2. **Verified** — scout is ≤ 100 m from the pin → "Begin Stream" unlocks.
///   3. **Too Far**  — scout is > 100 m → error shown; auto-rechecks every 5 s
///      and transitions to verified as soon as the threshold is met.
class GpsVerificationPage extends StatefulWidget {
  static const String route = '/gps-verification';

  const GpsVerificationPage({super.key});

  @override
  State<GpsVerificationPage> createState() => _GpsVerificationPageState();
}

class _GpsVerificationPageState extends State<GpsVerificationPage>
    with TickerProviderStateMixin {
  late final MissionEntity _mission;

  /// Drives the pulsing ring animation around the dot.
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  _GpsState _state = _GpsState.locating;
  double _distanceMeters = 0;

  /// 0.0 → 1.0 value used to drive the animated progress bar width.
  double _progressFraction = 0.0;

  /// Background timer that silently re-checks distance when in [_GpsState.tooFar].
  Timer? _recheckTimer;

  // Threshold lives in LocationService.missionProximityMeters (100 m).

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _mission = Get.arguments as MissionEntity;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _runVerification());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _recheckTimer?.cancel();
    super.dispose();
  }

  // ── Verification flow ─────────────────────────────────────────────────────

  Future<void> _runVerification() async {
    if (!mounted) return;

    setState(() {
      _state = _GpsState.locating;
      _progressFraction = 0.0;
    });

    // Single-frame pause so the empty bar is visible before filling.
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    // Animate progress bar to ~35% — the "GPS locating" phase.
    setState(() => _progressFraction = 0.35);

    // Let the locating animation run, then perform the actual distance check.
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    await _checkDistance();
  }

  Future<void> _checkDistance() async {
    if (!mounted) return;
    _recheckTimer?.cancel();

    try {
      final locationService = Get.find<LocationService>();

      // Prefer the cached position; fall back to a fresh GPS fix if needed.
      final mLat = _mission.latitude ?? 0.0;
      final mLng = _mission.longitude ?? 0.0;

      double? dist = locationService.distanceTo(mLat, mLng);
      if (dist == null) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        dist = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          mLat,
          mLng,
        );
      }

      if (!mounted) return;
      _distanceMeters = dist;

      if (dist <= LocationService.missionProximityMeters) {
        _pulseCtrl.stop(); // freeze rings at expanded state
        setState(() {
          _state = _GpsState.verified;
          _progressFraction = 1.0;
        });
      } else {
        setState(() => _state = _GpsState.tooFar);
        // Auto-recheck every 5 s so the UI transitions automatically when the
        // scout walks into range.
        _recheckTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _silentRecheck(),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _state = _GpsState.tooFar);
    }
  }

  /// Lightweight re-check using the location service's cached position only —
  /// no GPS call, no UI state reset, just refreshes distance and auto-promotes
  /// to verified when the threshold is met.
  Future<void> _silentRecheck() async {
    if (!mounted || _state == _GpsState.verified) {
      _recheckTimer?.cancel();
      return;
    }

    try {
      final locationService = Get.find<LocationService>();
      final dist = locationService.distanceTo(
        _mission.latitude ?? 0.0,
        _mission.longitude ?? 0.0,
      );
      if (dist == null || !mounted) return;

      setState(() => _distanceMeters = dist);

      if (dist <= LocationService.missionProximityMeters) {
        _recheckTimer?.cancel();
        _pulseCtrl.stop();
        setState(() {
          _state = _GpsState.verified;
          _progressFraction = 1.0;
        });
      }
    } catch (_) {}
  }

  /// Manual retry — resets to locating and re-runs the full flow.
  void _onRetry() {
    _recheckTimer?.cancel();
    if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    _runVerification();
  }

  void _onBeginStream() {
    Get.toNamed(StreamPage.route, arguments: _mission);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color get _accentColor => _state == _GpsState.tooFar
      ? ScoutColors.scoutMarker // orange for error
      : ScoutColors.primary; // green for locating / verified

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScoutColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Animated GPS dot ─────────────────────────────────────────────
            _GpsDotIcon(
              state: _state,
              pulseAnim: _pulseAnim,
              accentColor: _accentColor,
            ),

            32.verticalSpace,

            // ── Title ────────────────────────────────────────────────────────
            _buildTitle(),

            12.verticalSpace,

            // ── Subtitle ─────────────────────────────────────────────────────
            _buildSubtitle(),

            40.verticalSpace,

            // ── Progress bar ─────────────────────────────────────────────────
            _buildProgressBar(),

            32.verticalSpace,

            // ── CTA ──────────────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCta(),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildTitle() {
    final title = switch (_state) {
      _GpsState.locating => 'GPS Verification',
      _GpsState.verified => '✓ On Location',
      _GpsState.tooFar => '✕ Not On Location',
    };

    return Text(
      title,
      style: TextStyle(
        color: _state == _GpsState.tooFar
            ? ScoutColors.scoutMarker
            : ScoutColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSubtitle() {
    final String subtitle;
    switch (_state) {
      case _GpsState.locating:
        subtitle =
            'You must be within 100m of the mission pin\nto begin streaming.';
        break;
      case _GpsState.verified:
        subtitle =
            'Location confirmed. You are within 100m\nof the mission pin.';
        break;
      case _GpsState.tooFar:
        final distLabel = _distanceMeters > 0
            ? '${_distanceMeters.toInt()}m away from the mission pin.'
            : 'too far from the mission pin.';
        subtitle = 'You are $distLabel\nMove closer to begin streaming.';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Text(
        subtitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ScoutColors.textSecondary,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final label = switch (_state) {
      _GpsState.locating => 'LOCATING...',
      _GpsState.verified => 'READY',
      _GpsState.tooFar => 'OUT OF RANGE',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                // Track
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ScoutColors.surface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Fill — animated width
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  height: 3,
                  width: constraints.maxWidth * _progressFraction,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          8.verticalSpace,
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: _state == _GpsState.verified
                  ? ScoutColors.primary
                  : ScoutColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildCta() {
    switch (_state) {
      case _GpsState.verified:
        return Padding(
          key: const ValueKey('begin'),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ElevatedButton(
            onPressed: _onBeginStream,
            style: ElevatedButton.styleFrom(
              backgroundColor: ScoutColors.primary,
              foregroundColor: ScoutColors.background,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Begin Stream',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        );

      case _GpsState.tooFar:
        return Padding(
          key: const ValueKey('retry'),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: OutlinedButton(
            onPressed: _onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: ScoutColors.textSecondary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: ScoutColors.divider),
            ),
            child: const Text(
              'Check Again',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        );

      case _GpsState.locating:
        return const SizedBox.shrink(key: ValueKey('empty'));
    }
  }
}

// ── GPS dot icon ──────────────────────────────────────────────────────────────

/// Animated concentric-ring dot that represents GPS lock status.
///
/// * Locating  — single outer ring pulsing gently.
/// * Verified  — two static rings expand outward, confirming GPS lock.
/// * Too Far   — single outer ring pulsing in orange/warning colour.
class _GpsDotIcon extends StatelessWidget {
  final _GpsState state;
  final Animation<double> pulseAnim;
  final Color accentColor;

  const _GpsDotIcon({
    required this.state,
    required this.pulseAnim,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outermost ring — pulsing during locating/tooFar ─────────────────
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) {
              final baseSize = state == _GpsState.verified ? 150.0 : 118.0;
              final size = state == _GpsState.verified
                  ? baseSize
                  : baseSize + (pulseAnim.value * 14);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withAlpha(
                      state == _GpsState.verified ? 35 : 50,
                    ),
                    width: 1,
                  ),
                ),
              );
            },
          ),

          // ── Inner ring — only shown on verified ──────────────────────────────
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: state == _GpsState.verified ? 1.0 : 0.0,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withAlpha(70),
                  width: 1,
                ),
              ),
            ),
          ),

          // ── Centre dot with radial glow ──────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withAlpha(18),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withAlpha(
                    state == _GpsState.verified ? 90 : 55,
                  ),
                  blurRadius: state == _GpsState.verified ? 34 : 24,
                  spreadRadius: state == _GpsState.verified ? 6 : 3,
                ),
              ],
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withAlpha(110),
                      blurRadius: 18,
                      spreadRadius: 2,
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
