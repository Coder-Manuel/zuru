import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

extension StringExt on String? {
  String get inital {
    if (this == null) return '--';
    if (this!.isEmpty) return '--';
    final words = this!.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    String initials = '';
    for (final word in words) {
      if (word.isNotEmpty) {
        initials += word[0].toUpperCase();
      }
    }
    return initials;
  }

  bool get isStrongPassword {
    if (this == null) return false;
    if (this!.isEmpty) return false;
    final regExp = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9])\S{8,}$',
    );
    return regExp.hasMatch(this!);
  }
}

extension DateTimeExt on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return DateFormat('MMM d').format(this);
    return DateFormat('MMM d, yyyy').format(this);
  }
}

extension NullableDateTimeExt on DateTime? {
  String get timeAgo {
    if (this == null) return '';
    final now = DateTime.now();
    final diff = now.difference(this!);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return DateFormat('MMM d').format(this!);
    return DateFormat('MMM d, yyyy').format(this!);
  }
}

extension NumExt on num {
  bool get isApiSuccess => this == 200 || this == 201;

  String get asCurrency {
    final oCcy = NumberFormat("#,##0", "en_US");
    return oCcy.format(this);
  }

  String get formatDistance {
    if (this > 999) return '${(this / 1000).toPrecision(2)}km';
    return '${round()}m';
  }

  String get formatDuration {
    final h = this ~/ 3600;
    final m = (this % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

extension PositionExt on Position {
  bool isSameAs(Position value) =>
      value.latitude == latitude && value.longitude == longitude;
}
