import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

/// Full-screen, TikTok/Reels-style vertical video player.
///
/// - Vertically swipe between [urls]; only the active page plays.
/// - Tap the screen to toggle play/pause.
/// - The big play icon shows **only when paused**.
/// - A scrubbable seek bar sits at the bottom.
class ReelsPlayerPage extends StatefulWidget {
  final List<String> urls;
  final List<String>? titles;
  final int initialIndex;

  const ReelsPlayerPage({
    super.key,
    required this.urls,
    this.titles,
    this.initialIndex = 0,
  });

  /// Convenience launcher.
  static Future<void> open(
    List<String> urls, {
    int initialIndex = 0,
    List<String>? titles,
  }) {
    if (urls.isEmpty) return Future.value();
    return Get.to<void>(
          () => ReelsPlayerPage(
            urls: urls,
            titles: titles,
            initialIndex: initialIndex.clamp(0, urls.length - 1),
          ),
          fullscreenDialog: true,
          transition: Transition.downToUp,
        ) ??
        Future.value();
  }

  @override
  State<ReelsPlayerPage> createState() => _ReelsPlayerPageState();
}

class _ReelsPlayerPageState extends State<ReelsPlayerPage> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _ReelVideo(
              key: ValueKey(widget.urls[i]),
              url: widget.urls[i],
              title: (widget.titles != null && i < widget.titles!.length)
                  ? widget.titles![i]
                  : null,
              isActive: i == _index,
            ),
          ),

          // Close button.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: Get.back,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),

          // Page indicator (only when there's more than one clip).
          if (widget.urls.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 18,
              right: 16,
              child: Text(
                '${_index + 1} / ${widget.urls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReelVideo extends StatefulWidget {
  final String url;
  final String? title;
  final bool isActive;

  const _ReelVideo({
    super.key,
    required this.url,
    required this.isActive,
    this.title,
  });

  @override
  State<_ReelVideo> createState() => _ReelVideoState();
}

class _ReelVideoState extends State<_ReelVideo> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      controller.addListener(_onTick);
      if (!mounted) return;
      setState(() => _initialized = true);
      if (widget.isActive) controller.play();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_ReelVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null || !_initialized) return;
    if (widget.isActive && !oldWidget.isActive) {
      controller.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      controller
        ..pause()
        ..seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !_initialized) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Text(
          'Could not play this clip',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final controller = _controller;
    if (!_initialized || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    final isPlaying = controller.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover-fit video.
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),

          // Play icon — visible only when paused.
          if (!isPlaying)
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(90),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),

          // Title + seek bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(180)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title != null && widget.title!.isNotEmpty) ...[
                    Text(
                      widget.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFD4A520),
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
