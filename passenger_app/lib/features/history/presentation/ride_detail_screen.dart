import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/map_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/states.dart';
import '../../rides/presentation/active_ride_controller.dart';
import '../../rides/presentation/fare_estimate_screen.dart';
import 'ride_history_screen.dart';

class RideDetailScreen extends ConsumerWidget {
  const RideDetailScreen({required this.rideId, super.key});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ride = ref.watch(rideByIdProvider(rideId));
    final locale = Localizations.localeOf(context).toString();
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return AppScaffold(
      title: l.rideDetail,
      constrainWidth: false,
      body: ride.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonBox(height: 180, radius: AppRadius.lg),
              SizedBox(height: AppSpacing.lg),
              SkeletonBox(height: 20, width: 200),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 14, width: 140),
            ],
          ),
        ),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(rideByIdProvider(rideId)),
        ),
        data: (r) {
          final (statusLabel, color, bg) = rideStatusStyle(l, r.status);
          final pickup = LatLng(r.pickup.lat, r.pickup.lng);
          final dropoff = LatLng(r.dropoff.lat, r.dropoff.lng);
          return ListView(
            children: [
              SizedBox(
                height: 180,
                child: MapView(
                  initialTarget: LatLng(
                    (pickup.latitude + dropoff.latitude) / 2,
                    (pickup.longitude + dropoff.longitude) / 2,
                  ),
                  initialZoom: 12.5,
                  liteMode: true,
                  interactive: false,
                  markers: {
                    MapMarkers.pickup(pickup),
                    MapMarkers.dropoff(dropoff),
                  },
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.maxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusPill(
                              label: statusLabel,
                              color: color,
                              background: bg,
                            ),
                            const Spacer(),
                            Text(
                              Formatters.currency(r.fare),
                              style: AppTypography.numeric.copyWith(
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          Formatters.dateTime(
                            r.createdAt.toLocal(),
                            locale: locale,
                          ),
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _kv(
                          Icons.trip_origin_rounded,
                          AppColors.pickupMarker,
                          r.pickup.name,
                          r.pickup.address,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _kv(
                          Icons.location_on_rounded,
                          AppColors.dropoffMarker,
                          r.dropoff.name,
                          r.dropoff.address,
                        ),
                        const Divider(height: AppSpacing.xxl),
                        _row(
                          vehicleLabel(l, r.vehicleType),
                          Icon(vehicleIcon(r.vehicleType), size: 20),
                        ),
                        if (r.distanceMeters != null)
                          _row(
                            l.fareDistance,
                            Text(
                              Formatters.distance(r.distanceMeters!, bn: isBn),
                            ),
                          ),
                        if (r.durationSeconds != null)
                          _row(
                            l.fareTime,
                            Text(
                              Formatters.duration(r.durationSeconds!, bn: isBn),
                            ),
                          ),
                        if (r.driver != null)
                          _row(
                            l.driverLabel,
                            Text(
                              '${r.driver!.name} · ${r.driver!.vehiclePlate}',
                            ),
                          ),
                        _row(
                          l.rideId,
                          SelectableText(r.id, style: AppTypography.caption),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(IconData icon, Color color, String title, String sub) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.bodyStrong),
            if (sub.isNotEmpty) Text(sub, style: AppTypography.caption),
          ],
        ),
      ),
    ],
  );

  Widget _row(String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.bodySecondary)),
        DefaultTextStyle.merge(style: AppTypography.body, child: value),
      ],
    ),
  );
}
