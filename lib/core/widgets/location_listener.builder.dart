import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/location_service/location_service.dart';

class LocationListenerBuilder extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? id;
  final Widget Function(BuildContext context, double? distance) builder;

  const LocationListenerBuilder({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.builder,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    final locationService = Get.find<LocationService>();
    return Obx(() {
      final _ = locationService.position.value;
      final distance = locationService.distanceTo(latitude, longitude);
      return builder(context, distance);
    });
  }
}
