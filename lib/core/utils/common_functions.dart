import 'dart:convert';
import 'dart:math';

import 'package:zuru/core/utils/error_wrapper.dart';

class CommonFunctions {
  static final String _library = 'Common Functions';

  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final meters = ErrorWrapper.sync<double>(
      () {
        const R = 6371000.0;
        final phi1 = lat1 * pi / 180;
        final phi2 = lat2 * pi / 180;
        final dPhi = (lat2 - lat1) * pi / 180;
        final dLam = (lng2 - lng1) * pi / 180;
        final a =
            sin(dPhi / 2) * sin(dPhi / 2) +
            cos(phi1) * cos(phi2) * sin(dLam / 2) * sin(dLam / 2);
        return R * 2 * atan2(sqrt(a), sqrt(1 - a));
      },
      library: _library,
      onError: (_) => 0,
      description: 'while calculating distance',
    );
    return meters!;
  }

  static Map<String, dynamic>? decodeJwtPayload(String token) {
    return ErrorWrapper.sync<Map<String, dynamic>?>(
      () {
        final parts = token.split('.');
        if (parts.length != 3) return null;
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        return jsonDecode(utf8.decode(base64Url.decode(normalized)));
      },
      onError: (_) => null,
      library: _library,
      description: 'while decoding jwt',
    );
  }
}
