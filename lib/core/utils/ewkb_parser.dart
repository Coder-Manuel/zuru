import 'dart:typed_data';

class EwkbParser {
  EwkbParser._();

  static ({double? latitude, double? longitude}) parsePoint(String? hex) {
    if (hex == null || hex.length < 42) {
      return (latitude: null, longitude: null);
    }

    try {
      final bytes = Uint8List.fromList([
        for (int i = 0; i < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ]);

      final data = ByteData.view(bytes.buffer);
      final endian = bytes[0] == 0x01 ? Endian.little : Endian.big;

      final wkbType = data.getUint32(1, endian);
      final hasSrid = (wkbType & 0x20000000) != 0;

      final xOffset = 1 + 4 + (hasSrid ? 4 : 0);

      final longitude = data.getFloat64(xOffset, endian);
      final latitude = data.getFloat64(xOffset + 8, endian);

      return (latitude: latitude, longitude: longitude);
    } catch (_) {
      return (latitude: null, longitude: null);
    }
  }
}
