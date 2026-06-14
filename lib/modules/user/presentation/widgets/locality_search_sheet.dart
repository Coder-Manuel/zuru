import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/user/presentation/controllers/scout_profile_edit_controller.dart';

/// Opens the "Search Locality" bottom sheet — a live Google Places autocomplete
/// that resolves the chosen place to a formatted address + coordinates on the
/// [ScoutProfileEditController].
Future<void> showLocalitySearchSheet(BuildContext context) {
  final controller = Get.find<ScoutProfileEditController>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _LocalitySearchSheet(),
  ).whenComplete(controller.onLocalitySheetClosed);
}

class _LocalitySearchSheet extends StatefulWidget {
  const _LocalitySearchSheet();

  @override
  State<_LocalitySearchSheet> createState() => _LocalitySearchSheetState();
}

class _LocalitySearchSheetState extends State<_LocalitySearchSheet> {
  final controller = Get.find<ScoutProfileEditController>();
  final _searchCTRL = TextEditingController();

  @override
  void dispose() {
    _searchCTRL.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Locality',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      'Search a place — we’ll save the address and pin it on the map',
                      style: TextStyle(color: bodyColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: Get.back,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: scheme.onSurface,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          20.verticalSpace,
          TextField(
            controller: _searchCTRL,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: scheme.onSurface, fontSize: 15),
            onChanged: controller.searchLocality,
            decoration: InputDecoration(
              hintText: 'Search town, area or address…',
              hintStyle: TextStyle(color: bodyColor),
              prefixIcon: Icon(Icons.search_rounded, color: bodyColor),
              suffixIcon: Obx(
                () => controller.isSearchingLocality.value
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              filled: true,
              fillColor: scheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          16.verticalSpace,
          Flexible(
            child: Obx(() {
              final suggestions = controller.localitySuggestions;
              final query = _searchCTRL.text.trim();

              if (controller.isResolvingLocality.value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                );
              }

              if (suggestions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    query.isEmpty
                        ? 'Start typing to search locations'
                        : controller.isSearchingLocality.value
                        ? 'Searching…'
                        : 'No matches for "$query"',
                    style: TextStyle(color: bodyColor, fontSize: 14),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                separatorBuilder: (_, _) =>
                    Divider(color: bodyColor?.withAlpha(30), height: 1),
                itemBuilder: (_, i) {
                  final s = suggestions[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.place_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                    title: Text(
                      s.mainText,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: s.secondaryText.isEmpty
                        ? null
                        : Text(
                            s.secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: bodyColor, fontSize: 13),
                          ),
                    onTap: () => controller.selectLocalitySuggestion(s),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
