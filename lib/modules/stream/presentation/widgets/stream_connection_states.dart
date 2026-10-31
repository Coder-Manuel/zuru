import 'package:flutter/material.dart';

/// Covers the video while a connection is down, with the grace seconds left.
///
/// Used for this device reconnecting and for the other participant dropping,
/// on both the guide's and the viewer's page.
class StreamReconnectingView extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Grace seconds left, or null to leave the countdown out.
  final int? secondsLeft;
  final Color accent;

  const StreamReconnectingView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.secondsLeft,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(color: accent, strokeWidth: 2),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                secondsLeft == null ? subtitle : '$subtitle (${secondsLeft}s)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen notice with an optional action, e.g. the other participant
/// not coming back, or this device's connection being lost.
class StreamNoticeView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isBusy;

  const StreamNoticeView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.actionLabel,
    this.onAction,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withAlpha(30),
                ),
                child: Icon(icon, color: accent, size: 42),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: isBusy ? null : onAction,
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: accent.withAlpha(120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
