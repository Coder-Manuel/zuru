import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/modules/missions/domain/entities/place_suggestion.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/location_picker_controller.dart';

class LocationPickerPage extends GetView<LocationPickerController> {
  static const String route = '/location-picker';

  const LocationPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: Stack(
        children: [
          // ── Full-screen map ────────────────────────────────────────────────
          Obx(
            () => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: controller.mapCenter.value,
                zoom: 15,
              ),
              onMapCreated: controller.onMapCreated,
              onCameraMove: controller.onCameraMove,
              onCameraIdle: controller.onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              // Dark-ish map style — keep map tiles dark to match app theme
              colorScheme: MapColorScheme.dark,
              style: _darkMapStyle,
            ),
          ),

          // ── Fixed centre pin ──────────────────────────────────────────────
          const _CentrePin(),

          // ── Top overlay: back button + search bar ─────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Row: back + search field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      // Back button
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Get.back(),
                      ),
                      const SizedBox(width: 10),

                      // Search text field
                      Expanded(
                        child: _SearchField(
                          controller: controller.searchCTRL,
                          onChanged: controller.onSearchChanged,
                        ),
                      ),
                    ],
                  ),
                ),

                // Autocomplete suggestions dropdown
                Obx(() {
                  if (!controller.showSuggestions.value) {
                    return const SizedBox.shrink();
                  }
                  return _SuggestionsList(
                    suggestions: controller.suggestions.toList(),
                    onTap: controller.onSuggestionTap,
                  );
                }),
              ],
            ),
          ),

          // ── "Use my location" FAB ─────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 160,
            child: Obx(
              () => _CircleIconButton(
                icon: controller.isFetchingLocation.value
                    ? null
                    : Icons.my_location,
                isLoading: controller.isFetchingLocation.value,
                onTap: controller.useCurrentLocation,
                size: 48,
              ),
            ),
          ),

          // ── Bottom confirmation bar ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ConfirmBar(controller: controller),
          ),
        ],
      ),
    );
  }
}

// ─── Fixed centre pin ─────────────────────────────────────────────────────────

class _CentrePin extends StatelessWidget {
  const _CentrePin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ClientColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ClientColors.primary.withAlpha(100),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.black, size: 20),
          ),
          // Pin stem
          Container(width: 2, height: 16, color: ClientColors.primary),
          // Shadow dot on the map
          Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: ClientColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search address…',
        hintStyle: const TextStyle(
          color: ClientColors.textSecondary,
          fontSize: 15,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: ClientColors.textSecondary,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.close,
            color: ClientColors.textSecondary,
            size: 18,
          ),
          onPressed: () {
            controller.clear();
            onChanged('');
          },
        ),
        filled: true,
        fillColor: ClientColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: ClientColors.divider.withAlpha(80),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClientColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Suggestions dropdown ─────────────────────────────────────────────────────

class _SuggestionsList extends StatelessWidget {
  final List<PlaceSuggestionEntity> suggestions;
  final void Function(PlaceSuggestionEntity) onTap;

  const _SuggestionsList({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClientColors.divider.withAlpha(80), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((s) {
          final isLast = suggestions.last == s;
          return _SuggestionTile(
            suggestion: s,
            isLast: isLast,
            onTap: () => onTap(s),
          );
        }).toList(),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final PlaceSuggestionEntity suggestion;
  final bool isLast;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: ClientColors.divider.withAlpha(60),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: ClientColors.primary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.mainText,
                    style: const TextStyle(
                      color: ClientColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.secondaryText,
                      style: const TextStyle(
                        color: ClientColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm bar (bottom) ─────────────────────────────────────────────────────

class _ConfirmBar extends StatelessWidget {
  final LocationPickerController controller;

  const _ConfirmBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: ClientColors.divider.withAlpha(80), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ClientColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: ClientColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  if (controller.isReverseGeocoding.value) {
                    return const _AddressShimmer();
                  }
                  final addr = controller.selectedAddress.value;
                  return Text(
                    addr.isEmpty ? 'Move the pin to set a location' : addr,
                    style: TextStyle(
                      color: addr.isEmpty
                          ? ClientColors.textSecondary
                          : ClientColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: controller.confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: ClientColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address shimmer (while reverse-geocoding) ────────────────────────────────

class _AddressShimmer extends StatefulWidget {
  const _AddressShimmer();

  @override
  State<_AddressShimmer> createState() => _AddressShimmerState();
}

class _AddressShimmerState extends State<_AddressShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.8).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        height: 14,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ClientColors.divider.setOpacity(_anim.value),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

// ─── Circle icon button ───────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback onTap;
  final double size;
  final bool isLoading;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ClientColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: ClientColors.primary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ClientColors.primary,
                  ),
                ),
              )
            : Icon(icon, color: ClientColors.textPrimary, size: 20),
      ),
    );
  }
}

// ─── Google Maps dark style JSON ──────────────────────────────────────────────

const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0d1525"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0d1525"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8896ab"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill",
    "stylers": [{"color": "#d4a520"}]},
  {"featureType": "poi", "elementType": "labels.text.fill",
    "stylers": [{"color": "#8896ab"}]},
  {"featureType": "poi.park", "elementType": "geometry",
    "stylers": [{"color": "#141e2e"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill",
    "stylers": [{"color": "#5a6a7a"}]},
  {"featureType": "road", "elementType": "geometry",
    "stylers": [{"color": "#1a2535"}]},
  {"featureType": "road", "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]},
  {"featureType": "road", "elementType": "labels.text.fill",
    "stylers": [{"color": "#8896ab"}]},
  {"featureType": "road.highway", "elementType": "geometry",
    "stylers": [{"color": "#243347"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke",
    "stylers": [{"color": "#1a2535"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill",
    "stylers": [{"color": "#aab4c0"}]},
  {"featureType": "transit", "elementType": "geometry",
    "stylers": [{"color": "#141e2e"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill",
    "stylers": [{"color": "#8896ab"}]},
  {"featureType": "water", "elementType": "geometry",
    "stylers": [{"color": "#091525"}]},
  {"featureType": "water", "elementType": "labels.text.fill",
    "stylers": [{"color": "#4a5568"}]},
  {"featureType": "water", "elementType": "labels.text.stroke",
    "stylers": [{"color": "#091525"}]}
]
''';
