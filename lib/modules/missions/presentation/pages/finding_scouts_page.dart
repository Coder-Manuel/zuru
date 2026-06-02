import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/finding_scouts_controller.dart';

class FindingScoutsPage extends GetView<FindingScoutsController> {
  static const String route = '/finding-scouts';

  const FindingScoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _CircleBackButton(),
                  const SizedBox(width: 14),
                  Text(
                    'Finding Scouts',
                    style: TextStyle(
                      color: ClientColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Radar ──────────────────────────────────────────────────────
            Center(
              child: Obx(
                () => _RadarWidget(
                  scoutDots: controller.radarDots
                      .map((d) => Offset(d.x, d.y))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Bottom section — toggles between scout list and fallback ──
            Expanded(
              child: Obx(() {
                final showFallback = controller.showNoScoutsFallback.value;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: showFallback
                      ? _NoScoutsFallback(
                          key: const ValueKey('fallback'),
                          countdown: controller.redirectCountdown.value,
                        )
                      : _ScoutsSection(
                          key: const ValueKey('scouts'),
                          controller: controller,
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scouts section (counter + animated list) ─────────────────────────────────

class _ScoutsSection extends StatelessWidget {
  final FindingScoutsController controller;
  const _ScoutsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Scouts notified counter
        Obx(
          () => Text(
            '${controller.scoutsNotified.value} SCOUTS NOTIFIED',
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Obx(
            () => _AnimatedScoutList(scouts: controller.scouts.toList()),
          ),
        ),
      ],
    );
  }
}

// ─── No-scouts fallback UI ────────────────────────────────────────────────────

class _NoScoutsFallback extends StatefulWidget {
  final int countdown;
  const _NoScoutsFallback({super.key, required this.countdown});

  @override
  State<_NoScoutsFallback> createState() => _NoScoutsFallbackState();
}

class _NoScoutsFallbackState extends State<_NoScoutsFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing broadcast icon
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: ClientColors.primary.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ClientColors.primary.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.sensors, color: ClientColors.primary, size: 40),
            ),
          ),
          const SizedBox(height: 28),

          // Heading
          Text(
            'No scouts nearby right now',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ClientColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Your mission has been posted and will be accepted by the next available scout.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 36),

          // Countdown chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: ClientColors.surface,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: ClientColors.divider.withAlpha(60),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_outlined,
                  color: ClientColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Returning to home in ${widget.countdown}s…',
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Radar widget (StatefulWidget — needs AnimationController) ────────────────

class _RadarWidget extends StatefulWidget {
  final List<Offset> scoutDots; // normalised [-1,1] coords

  const _RadarWidget({required this.scoutDots});

  @override
  State<_RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<_RadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepCtrl;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweepCtrl,
      builder: (_, _) => CustomPaint(
        size: const Size(260, 260),
        painter: _RadarPainter(
          sweepProgress: _sweepCtrl.value,
          scoutDots: widget.scoutDots,
        ),
      ),
    );
  }
}

// ─── Radar CustomPainter ──────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final double sweepProgress; // 0..1
  final List<Offset> scoutDots;

  _RadarPainter({required this.sweepProgress, required this.scoutDots});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final sweepAngle = sweepProgress * 2 * math.pi;

    // ── Concentric rings ──────────────────────────────────────────────────
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final ringRadii = [0.28, 0.48, 0.68, 0.88, 1.0];
    for (int i = 0; i < ringRadii.length; i++) {
      ringPaint.color = ClientColors.primary.withAlpha(
        (50 - i * 8).clamp(10, 60),
      );
      canvas.drawCircle(center, maxRadius * ringRadii[i], ringPaint);
    }

    // ── Sweep sector (filled arc with gradient opacity) ───────────────────
    const sweepWidth = math.pi / 2.2; // ~81° wide
    final sweepStart = sweepAngle - sweepWidth;

    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        sweepStart,
        sweepWidth,
        false,
      )
      ..close();

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: sweepStart,
        endAngle: sweepAngle,
        colors: [
          ClientColors.primary.withAlpha(0),
          ClientColors.primary.withAlpha(80),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawPath(sweepPath, sweepPaint);

    // ── Sweep leading edge line ────────────────────────────────────────────
    final edgePaint = Paint()
      ..color = ClientColors.primary.withAlpha(180)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      center,
      Offset(
        center.dx + maxRadius * math.cos(sweepAngle),
        center.dy + maxRadius * math.sin(sweepAngle),
      ),
      edgePaint,
    );

    // ── Center dot (user — teal) ──────────────────────────────────────────
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF22C55E));

    // ── Scout dots (green, appear once discovered) ─────────────────────────
    for (final dot in scoutDots) {
      final pos = Offset(
        center.dx + dot.dx * maxRadius,
        center.dy + dot.dy * maxRadius,
      );
      // Glow
      canvas.drawCircle(
        pos,
        9,
        Paint()
          ..color = const Color(0xFF22C55E).withAlpha(50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Core
      canvas.drawCircle(pos, 5, Paint()..color = const Color(0xFF22C55E));
    }

    // ── Amber reference dot (nearby fixed point) ───────────────────────────
    final refPos = Offset(
      center.dx + maxRadius * 0.18,
      center.dy + maxRadius * 0.08,
    );
    canvas.drawCircle(refPos, 7, Paint()..color = ClientColors.primary);
    canvas.drawCircle(
      refPos,
      12,
      Paint()
        ..color = ClientColors.primary.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.sweepProgress != sweepProgress ||
      oldDelegate.scoutDots.length != scoutDots.length;
}

// ─── Animated scout list ──────────────────────────────────────────────────────

class _AnimatedScoutList extends StatefulWidget {
  final List<NearbyScout> scouts;
  const _AnimatedScoutList({required this.scouts});

  @override
  State<_AnimatedScoutList> createState() => _AnimatedScoutListState();
}

class _AnimatedScoutListState extends State<_AnimatedScoutList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final List<NearbyScout> _displayed = [];

  @override
  void didUpdateWidget(_AnimatedScoutList old) {
    super.didUpdateWidget(old);
    // Insert any newly added scouts
    for (int i = _displayed.length; i < widget.scouts.length; i++) {
      _displayed.add(widget.scouts[i]);
      _listKey.currentState?.insertItem(
        i,
        duration: const Duration(milliseconds: 420),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      initialItemCount: 0,
      itemBuilder: (ctx, index, animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(
            opacity: animation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScoutCard(scout: _displayed[index]),
            ),
          ),
        );
      },
    );
  }
}

// ─── Scout card ───────────────────────────────────────────────────────────────

class _ScoutCard extends StatelessWidget {
  final NearbyScout scout;
  const _ScoutCard({required this.scout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ClientColors.divider.withAlpha(60),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar — initials derived from User.displayName
          _InitialsAvatar(name: scout.user.scoutProfile?.displayName ?? '--'),
          const SizedBox(width: 12),

          // Name + distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scout.user.scoutProfile?.displayName ?? '--',
                  style: TextStyle(
                    color: ClientColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${scout.distanceMeters.formatDistance} · ${scout.user.scoutProfile?.totalReviews ?? 0} missions',
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Rating + online badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    scout.user.scoutProfile?.rating?.toStringAsFixed(1) ?? '–',
                    style: TextStyle(
                      color: ClientColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.star, color: ClientColors.primary, size: 15),
                ],
              ),
              const SizedBox(height: 6),
              _OnlineBadge(isOnline: scout.user.isOnline ?? false),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Initials avatar ──────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2B3D),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: ClientColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─── Online badge ─────────────────────────────────────────────────────────────

class _OnlineBadge extends StatelessWidget {
  final bool isOnline;
  const _OnlineBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF14532D) : const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOnline ? 'Available' : 'Offline',
        style: TextStyle(
          color: isOnline ? Color(0xFF22C55E) : ClientColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Circle back button ───────────────────────────────────────────────────────

class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ClientColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back,
          color: ClientColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
