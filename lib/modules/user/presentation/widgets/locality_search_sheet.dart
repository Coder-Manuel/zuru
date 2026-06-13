import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/utils/size.util.dart';

/// Preset localities offered before falling back to a custom entry.
const _kPresetLocalities = [
  'Nairobi',
  'Mombasa',
  'Kisumu',
  'Nakuru',
  'Eldoret',
  'Homabay',
  'Kisii',
  'Nyeri',
  'Thika',
  'Machakos',
  'Kakamega',
  'Meru',
];

/// Opens the "Search Locality" bottom sheet. Calls [onSelected] with the
/// chosen (preset or custom) locality.
Future<void> showLocalitySearchSheet(
  BuildContext context, {
  String? initial,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LocalitySearchSheet(initial: initial, onSelected: onSelected),
  );
}

class _LocalitySearchSheet extends StatefulWidget {
  final String? initial;
  final ValueChanged<String> onSelected;

  const _LocalitySearchSheet({this.initial, required this.onSelected});

  @override
  State<_LocalitySearchSheet> createState() => _LocalitySearchSheetState();
}

class _LocalitySearchSheetState extends State<_LocalitySearchSheet> {
  late final TextEditingController _searchCTRL;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCTRL = TextEditingController(text: widget.initial ?? '');
    _query = widget.initial ?? '';
  }

  @override
  void dispose() {
    _searchCTRL.dispose();
    super.dispose();
  }

  List<String> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _kPresetLocalities;
    return _kPresetLocalities
        .where((l) => l.toLowerCase().contains(q))
        .toList();
  }

  void _select(String value) {
    widget.onSelected(value);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final matches = _matches;
    final query = _query.trim();

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
                      'Select from suggestions or enter custom location',
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
            style: TextStyle(color: scheme.onSurface, fontSize: 15),
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search…',
              hintStyle: TextStyle(color: bodyColor),
              prefixIcon: Icon(Icons.search_rounded, color: bodyColor),
              filled: true,
              fillColor: scheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          20.verticalSpace,
          Text(
            'SUGGESTED LOCALITIES',
            style: TextStyle(
              color: bodyColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          16.verticalSpace,
          if (matches.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matches
                  .map(
                    (l) => GestureDetector(
                      onTap: () => _select(l),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: bodyColor?.withAlpha(50) ?? Colors.grey,
                          ),
                        ),
                        child: Text(
                          l,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Center(
              child: Column(
                children: [
                  Text(
                    'No presets match "$query"',
                    style: TextStyle(color: bodyColor, fontSize: 14),
                  ),
                  16.verticalSpace,
                  GestureDetector(
                    onTap: () => _select(query),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.primary.withAlpha(120)),
                      ),
                      child: Text(
                        'Use Custom: "$query"',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          24.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: Get.back,
              style: TextButton.styleFrom(
                backgroundColor: scheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
