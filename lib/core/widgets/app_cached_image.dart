import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// App-wide cached network image.
///
/// Wraps [CachedNetworkImage] with a shimmer placeholder and a graceful
/// fallback, and applies an optional [borderRadius]. Use this everywhere a
/// remote image is shown (avatars, thumbnails, etc.) so caching is consistent.
class AppCachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Shown when [url] is null/empty or the image fails to load.
  final Widget? fallback;

  /// Base/highlight colors for the loading shimmer.
  final Color baseColor;
  final Color highlightColor;

  const AppCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.baseColor = const Color(0xFF1A2535),
    this.highlightColor = const Color(0xFF243349),
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = (url == null || url!.isEmpty)
        ? _fallback
        : CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, _) => _shimmer,
            errorWidget: (_, _, _) => _fallback,
          );

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget get _shimmer => Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
    child: Container(width: width, height: height, color: baseColor),
  );

  Widget get _fallback =>
      fallback ??
      Container(
        width: width,
        height: height,
        color: baseColor,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: highlightColor),
      );
}
