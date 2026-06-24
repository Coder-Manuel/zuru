import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';

/// Opens the "Incoming Requests" sheet — the list of pending client requests
/// targeted at this scout, each reviewable or declinable inline.
Future<void> showIncomingRequestsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: ScoutColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _IncomingRequestsSheet(),
  );
}

class _IncomingRequestsSheet extends StatefulWidget {
  const _IncomingRequestsSheet();

  @override
  State<_IncomingRequestsSheet> createState() => _IncomingRequestsSheetState();
}

class _IncomingRequestsSheetState extends State<_IncomingRequestsSheet> {
  final controller = Get.find<RadarController>();
  Worker? _autoClose;

  @override
  void initState() {
    super.initState();
    // Close the sheet once every request has been handled.
    _autoClose = ever(controller.pendingRequests, (List list) {
      if (list.isEmpty && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoClose?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Column(
          children: [
            12.verticalSpace,
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ScoutColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Obx(() {
              final count = controller.pendingRequestCount;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        count == 0
                            ? 'NO PENDING REQUESTS'
                            : '$count PENDING REQUEST${count == 1 ? '' : 'S'}',
                        style: TextStyle(
                          color: ScoutColors.textAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: ScoutColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: ScoutColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // List
            Expanded(
              child: Obx(() {
                final requests = controller.pendingRequests;
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      'You’re all caught up',
                      style: TextStyle(
                        color: ScoutColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _RequestCard(request: requests[i]),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final MissionEntity request;

  const _RequestCard({required this.request});

  String get _whenLabel {
    final raw = request.scheduledAt;
    if (raw == null) return 'Now';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return 'Now';
    return DateFormat('EEE, MMM d • h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RadarController>();
    final client = request.client;
    final name = client?.fullName.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScoutColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScoutColors.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: ScoutColors.inputBg,
                backgroundImage:
                    (client?.avatarUrl != null && client!.avatarUrl!.isNotEmpty)
                    ? NetworkImage(client.avatarUrl!)
                    : null,
                child: (client?.avatarUrl == null || client!.avatarUrl!.isEmpty)
                    ? Text(
                        (name?.isNotEmpty ?? false) ? name![0] : '?',
                        style: const TextStyle(
                          color: ScoutColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (name?.isNotEmpty ?? false) ? name! : 'A client',
                      style: const TextStyle(
                        color: ScoutColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      request.type?.label ?? 'Live Request',
                      style: TextStyle(
                        color: ScoutColors.textAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                request.formattedPrice,
                style: const TextStyle(
                  color: ScoutColors.textAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          12.verticalSpace,

          // Schedule + duration
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: ScoutColors.textSecondary,
              ),
              5.horizontalSpace,
              Expanded(
                child: Text(
                  '$_whenLabel  ·  ${request.durationLabel}',
                  style: TextStyle(
                    color: ScoutColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          if (request.description.trim().isNotEmpty) ...[
            10.verticalSpace,
            Text(
              request.description.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ScoutColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],

          16.verticalSpace,

          // Actions
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final busy =
                      controller.decliningRequestId.value == request.id;
                  return OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => controller.declineRequest(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ScoutColors.textSecondary,
                      side: BorderSide(color: ScoutColors.divider, width: 1.2),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ScoutColors.textSecondary,
                            ),
                          )
                        : const Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                }),
              ),
              12.horizontalSpace,
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.openRequest(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScoutColors.primary,
                    foregroundColor: ScoutColors.background,
                    minimumSize: const Size.fromHeight(46),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Review',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
