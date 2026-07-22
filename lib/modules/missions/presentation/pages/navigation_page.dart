import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation_plus/flutter_mapbox_navigation_plus.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/services/location_service/location_service.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/location_listener.builder.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/update_mission_status.usecase.dart';
import 'package:zuru/modules/missions/presentation/pages/gps_verification_page.dart';

/// Full-screen turn-by-turn navigation page powered by Mapbox Navigation SDK.
///
/// Pass the target [MissionEntity] as `Get.arguments`.
///
/// Flow:
///   1. Page appears → shows "Preparing Navigation" loading screen.
///   2. `startNavigation()` launches the native Mapbox Navigation UI on top.
///   3a. Scout arrives / navigation ends naturally → [GpsVerificationPage].
///   3b. Scout presses the close button → pops back to mission details.
class NavigationPage extends StatefulWidget {
  static const String route = '/navigation';

  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final _updateMissionUsecase = Get.find<UpdateMissionStatusUseCase>();
  late final MissionEntity _mission;

  /// Prevents double-launch on hot-reload or lifecycle events.
  bool _launched = false;
  bool _hasError = false;
  String _errorMessage = '';

  /// Set to `true` when the scout taps the close button so the natural-end
  /// handler in [_launchNavigation] knows not to push [GpsVerificationPage].
  bool _closedManually = false;

  @override
  void initState() {
    super.initState();
    _mission = Get.arguments as MissionEntity;
    // Wait one frame so the loading UI is visible before the system call.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(const Duration(seconds: 2), _launchNavigation),
    );
  }

  // ── Navigation launch ─────────────────────────────────────────────────────

  Future<void> _launchNavigation() async {
    if (_launched || !mounted) return;
    _launched = true;

    try {
      // ── Proximity short-circuit ─────────────────────────────────────────
      // If the scout is already within 100 m of the mission, there is no
      // need for turn-by-turn navigation — go straight to GPS verification.
      final locationService = Get.find<LocationService>();
      final dist = locationService.distanceTo(
        _mission.latitude ?? 0.0,
        _mission.longitude ?? 0.0,
      );
      if (dist != null &&
          dist <= LocationService.missionProximityMeters &&
          mounted) {
        Get.off(() => const GpsVerificationPage(), arguments: _mission);
        return;
      }

      final wayPoints = _buildWayPoints();

      final options = MapBoxOptions(
        mode: MapBoxNavigationMode.drivingWithTraffic,
        simulateRoute: kDebugMode,
        language: 'en',
        units: VoiceUnits.metric,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        animateBuildRoute: true,
        longPressDestinationEnabled: false,
      );

      MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);

      // `startNavigation` opens the full-screen Mapbox Navigation UI.
      // The Future resolves only when the user closes/finishes navigation.
      await MapBoxNavigation.instance.startNavigation(
        wayPoints: wayPoints,
        options: options,
      );

      _updateStatus();

      if (!mounted || _closedManually) return;

      // Navigation ended naturally (arrived or SDK-initiated close) —
      // proceed to the GPS proximity verification step.
      Get.off(() => const GpsVerificationPage(), arguments: _mission);
    } catch (e) {
      log('==== NavigationPage error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Could not start navigation.\nPlease check your connection and try again.';
        });
      }
    }
  }

  Future<void> _onRouteEvent(RouteEvent e) async {
    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        final progress = e.data as RouteProgressEvent;
        if (progress.arrived == true) {
          log('==== NavigationPage: arrived');
          if (!_closedManually) {
            await _onClosePressed();
          }
        }
        break;
      case MapBoxEvent.on_arrival:
        log('==== NavigationPage: on_arrival — auto-finishing navigation');
        if (!_closedManually) {
          await _onClosePressed();
        }
        break;
      case MapBoxEvent.navigation_cancelled:
        log('==== NavigationPage: navigation_cancelled by user');
        _closedManually = true;
        if (mounted) Get.back();
        break;
      case MapBoxEvent.route_build_failed:
        if (mounted) setState(() => _hasError = true);
        break;
      default:
        break;
    }
  }

  /// Called by the close button — marks the session as manually dismissed so
  /// the [_launchNavigation] completion handler skips GPS verification.
  Future<void> _onClosePressed() async {
    _closedManually = true;
    try {
      final status = await MapBoxNavigation.instance.finishNavigation();
      log('==== NavigationPage: finishNavigation status $status');
    } catch (_) {}
    if (mounted) {
      log('==== NavigationPage: pushing GpsVerificationPage');
      Get.off(() => const GpsVerificationPage(), arguments: _mission);
    }
  }

  List<WayPoint> _buildWayPoints() {
    final locationService = Get.find<LocationService>();
    final lat = locationService.latitude;
    final lng = locationService.longitude;

    return [
      // Origin — scout's current position (silent, no announcement).
      if (lat != null && lng != null)
        WayPoint(
          name: 'Current Location',
          latitude: lat,
          longitude: lng,
          isSilent: true,
        ),

      // Destination — mission coordinates.
      WayPoint(
        name: _mission.address.isNotEmpty
            ? _mission.address
            : 'Live Check Location',
        latitude: _mission.latitude ?? 0.0,
        longitude: _mission.longitude ?? 0.0,
      ),
    ];
  }

  Future<void> _updateStatus() async {
    await _updateMissionUsecase(
      UpdateMissionStatusInput(
        missionId: _mission.id ?? '',
        status: MissionStatus.enroute,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScoutColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _CloseButton(onTap: _onClosePressed),
                  20.horizontalSpace,
                  Text(
                    'Navigation',
                    style: TextStyle(
                      color: ScoutColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: _hasError
                  ? _ErrorBody(
                      message: _errorMessage,
                      onRetry: () {
                        setState(() {
                          _hasError = false;
                          _launched = false;
                          _closedManually = false;
                        });
                        _launchNavigation();
                      },
                    )
                  : _PreparingBody(mission: _mission),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "Preparing Navigation" body ───────────────────────────────────────────────

class _PreparingBody extends StatefulWidget {
  final MissionEntity mission;
  const _PreparingBody({required this.mission});

  @override
  State<_PreparingBody> createState() => _PreparingBodyState();
}

class _PreparingBodyState extends State<_PreparingBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),

        // Animated pin icon
        ScaleTransition(
          scale: _scale,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ScoutColors.primary.withAlpha(20),
              border: Border.all(
                color: ScoutColors.primary.withAlpha(60),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.navigation_rounded,
              color: ScoutColors.primary,
              size: 40,
            ),
          ),
        ),

        32.verticalSpace,

        Text(
          'Preparing Navigation',
          style: TextStyle(
            color: ScoutColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),

        12.verticalSpace,

        Text(
          'Calculating the best route…',
          style: TextStyle(
            color: ScoutColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),

        28.verticalSpace,

        // Destination chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: ScoutColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ScoutColors.divider),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: ScoutColors.scoutMarker,
                size: 20,
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESTINATION',
                      style: TextStyle(
                        color: ScoutColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      widget.mission.address.isNotEmpty
                          ? widget.mission.address
                          : 'Live Check Location',
                      style: TextStyle(
                        color: ScoutColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              16.horizontalSpace,
              LocationListenerBuilder(
                latitude: widget.mission.latitude ?? 0.0,
                longitude: widget.mission.longitude ?? 0.0,
                builder: (_, distance) {
                  return Text(
                    distance?.formatDistance ?? '--',
                    style: TextStyle(
                      color: ScoutColors.textAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        28.verticalSpace,

        const _LoadingDots(),

        const Spacer(flex: 3),
      ],
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ScoutColors.surface,
          ),
          child: Icon(
            Icons.map_outlined,
            color: ScoutColors.textSecondary,
            size: 32,
          ),
        ),
        20.verticalSpace,
        Text(
          message,
          style: TextStyle(
            color: ScoutColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        24.verticalSpace,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: ScoutColors.primary,
              foregroundColor: ScoutColors.background,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Animated loading dots ─────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _activeDot = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _activeDot = (_activeDot + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == _activeDot ? 10 : 7,
          height: i == _activeDot ? 10 : 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == _activeDot
                ? ScoutColors.primary
                : ScoutColors.primary.withAlpha(60),
          ),
        );
      }),
    );
  }
}

// ── Close button ──────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ScoutColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chevron_left,
          color: ScoutColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}
