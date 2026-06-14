import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:zuru/core/utils/extensions.dart';

/// Renders a generated first-frame thumbnail for a remote video [url], with an
/// optional play-button overlay. Generated frames are cached in-memory per URL
/// so re-renders (and re-scrolls) are instant.
class VideoThumbnailView extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showPlayIcon;
  final double playIconSize;
  final Color accent;

  const VideoThumbnailView({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showPlayIcon = true,
    this.playIconSize = 44,
    this.accent = const Color(0xFFD4A520),
  });

  @override
  State<VideoThumbnailView> createState() => _VideoThumbnailViewState();
}

class _VideoThumbnailViewState extends State<VideoThumbnailView> {
  static final Map<String, Uint8List?> _cache = {};

  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VideoThumbnailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load();
  }

  Future<void> _load() async {
    if (_cache.containsKey(widget.url)) {
      setState(() {
        _bytes = _cache[widget.url];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    Uint8List? data;
    try {
      data = await VideoThumbnail.thumbnailData(
        video: widget.url,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 480,
        quality: 60,
      );
    } catch (_) {
      data = null;
    }

    _cache[widget.url] = data;
    if (mounted) {
      setState(() {
        _bytes = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = Shimmer.fromColors(
        baseColor: const Color(0xFF1A2535),
        highlightColor: const Color(0xFF243349),
        child: Container(color: const Color(0xFF1A2535)),
      );
    } else if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        fit: widget.fit,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      content = Container(
        color: const Color(0xFF101826),
        alignment: Alignment.center,
        child: const Icon(
          Icons.videocam_rounded,
          color: Color(0xFF8896AB),
          size: 28,
        ),
      );
    }

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        content,
        // Subtle bottom gradient for legibility of overlaid labels.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.setOpacity(0.85)],
            ),
          ),
        ),
        if (widget.showPlayIcon)
          Center(
            child: Container(
              width: widget.playIconSize,
              height: widget.playIconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent.withAlpha(40),
                border: Border.all(color: widget.accent, width: 1.5),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: widget.accent,
                size: widget.playIconSize * 0.55,
              ),
            ),
          ),
      ],
    );

    if (widget.borderRadius == null) return stack;
    return ClipRRect(borderRadius: widget.borderRadius!, child: stack);
  }
}
