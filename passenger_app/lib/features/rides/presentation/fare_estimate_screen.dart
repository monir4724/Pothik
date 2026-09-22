import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/map_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/states.dart';
import '../domain/ride_models.dart';
import 'active_ride_controller.dart';
import 'booking_draft_controller.dart';

/// Vehicle select + fare estimate. Handles: skeletons while quoting,
/// estimate failure with retry (distinct from booking failure), quote
/// expiry auto-refresh, and the booking-call failure/retry state.
class FareEstimateScreen extends ConsumerStatefulWidget {
  const FareEstimateScreen({super.key});

  @override
  ConsumerState<FareEstimateScreen> createState() => _FareEstimateScreenState();
}

class _FareEstimateScreenState extends ConsumerState<FareEstimateScreen> {
  VehicleType _selected = VehicleType.cng;
  Timer? _expiryTimer;
  final _note = TextEditingController();

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _note.dispose();
    super.dispose();
  }

  void _armExpiry(FareQuote q) {
    _expiryTimer?.cancel();
    final until = q.expiresAt.toUtc().difference(DateTime.now().toUtc());
    if (until.isNegative) return;
    _expiryTimer = Timer(until, () {
      if (!mounted) return;
      context.showSnack(AppLocalizations.of(context).quoteExpired);
      ref.invalidate(fareQuoteProvider);
    });
  }

  Future<void> _book(FareQuote q) async {
    if (q.isExpired) {
      ref.invalidate(fareQuoteProvider);
      return;
    }
    ref.read(bookingDraftProvider.notifier).setNote(_note.text.trim());
    await ref
        .read(activeRideProvider.notifier)
        .book(
          quoteId: q.quoteId,
          vehicleType: _selected,
          note: _note.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = ref.watch(bookingDraftProvider);
    final quote = ref.watch(fareQuoteProvider);
    final active = ref.watch(activeRideProvider);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    // Booking succeeded → router redirect will move us; also handle here in
    // case redirect is disabled for this route.
    ref.listen(activeRideProvider.select((s) => s.ride?.id), (prev, next) {
      if (next != null && prev != next && mounted) {
        ref.read(bookingDraftProvider.notifier).clear();
        context.go(Routes.finding(next));
      }
    });

    quote.whenData(_armExpiry);

    if (!draft.isComplete) {
      // Deep-linked here without a draft — nothing to quote.
      return AppScaffold(
        title: l.chooseRide,
        body: EmptyState(
          icon: Icons.route_rounded,
          title: l.whereTo,
          actionLabel: l.homeSearchHint,
          onAction: () => context.go(Routes.home),
        ),
      );
    }

    final pickup = LatLng(draft.pickup!.lat, draft.pickup!.lng);
    final dropoff = LatLng(draft.dropoff!.lat, draft.dropoff!.lng);

    return AppScaffold(
      title: l.chooseRide,
      constrainWidth: false,
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: MapView(
              initialTarget: LatLng(
                (pickup.latitude + dropoff.latitude) / 2,
                (pickup.longitude + dropoff.longitude) / 2,
              ),
              initialZoom: 12.5,
              liteMode: true,
              interactive: false,
              markers: {MapMarkers.pickup(pickup), MapMarkers.dropoff(dropoff)},
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: [pickup, dropoff],
                  color: AppColors.routePolyline,
                  width: 3,
                  patterns: [PatternItem.dash(16), PatternItem.gap(8)],
                ),
              },
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.maxContentWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _RouteSummary(
                      pickup: draft.pickup!,
                      dropoff: draft.dropoff!,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (active.bookingError != null) ...[
                      _BookingFailedCard(
                        onRetry: () => ref
                            .read(activeRideProvider.notifier)
                            .retryBooking(),
                        onDismiss: () => ref
                            .read(activeRideProvider.notifier)
                            .clearBookingError(),
                        isRetrying: active.isBooking,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    quote.when(
                      loading: () => Column(
                        children: [
                          for (var i = 0; i < 3; i++)
                            const Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.sm),
                              child: SkeletonBox(
                                height: 84,
                                radius: AppRadius.lg,
                              ),
                            ),
                        ],
                      ),
                      error: (e, _) => ErrorState(
                        title: l.estimateFailedTitle,
                        error: e,
                        onRetry: () => ref.invalidate(fareQuoteProvider),
                      ),
                      data: (q) => Column(
                        children: [
                          for (final est in q.estimates)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _VehicleCard(
                                estimate: est,
                                selected: est.vehicleType == _selected,
                                isBn: isBn,
                                onTap: () =>
                                    setState(() => _selected = est.vehicleType),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _note,
                            maxLength: 120,
                            decoration: InputDecoration(
                              hintText: l.noteToDriverHint,
                              prefixIcon: const Icon(
                                Icons.sticky_note_2_outlined,
                              ),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(l.fareNote, style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottom: quote.maybeWhen(
        data: (q) {
          final est = q.forVehicle(_selected);
          return AppButton.primary(
            label: est == null
                ? l.chooseRide
                : l.bookRide(
                    _vehicleName(l, _selected),
                    Formatters.currency(est.fare),
                  ),
            isLoading: active.isBooking,
            onPressed: est == null || active.hasActiveRide
                ? null
                : () => _book(q),
          );
        },
        orElse: () => AppButton.primary(label: l.chooseRide, onPressed: null),
      ),
    );
  }
}

String _vehicleName(AppLocalizations l, VehicleType t) => switch (t) {
  VehicleType.bike => l.vehicleBike,
  VehicleType.cng => l.vehicleCng,
  VehicleType.car => l.vehicleCar,
};

IconData vehicleIcon(VehicleType t) => switch (t) {
  VehicleType.bike => Icons.two_wheeler_rounded,
  VehicleType.cng => Icons.electric_rickshaw_rounded,
  VehicleType.car => Icons.directions_car_rounded,
};

String vehicleLabel(AppLocalizations l, VehicleType t) => _vehicleName(l, t);

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.pickup, required this.dropoff});

  final Place pickup;
  final Place dropoff;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _row(
              Icons.trip_origin_rounded,
              AppColors.pickupMarker,
              pickup.name,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 9),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 14,
                  child: VerticalDivider(width: 2, thickness: 2),
                ),
              ),
            ),
            _row(
              Icons.location_on_rounded,
              AppColors.dropoffMarker,
              dropoff.name,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, Color color, String text) => Row(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Text(
          text,
          style: AppTypography.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.estimate,
    required this.selected,
    required this.isBn,
    required this.onTap,
  });

  final FareEstimate estimate;
  final bool selected;
  final bool isBn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = _vehicleName(l, estimate.vehicleType);
    final fare = Formatters.currency(estimate.fare);
    final eta = Formatters.duration(
      estimate.etaToPickupSeconds ?? 300,
      bn: isBn,
    );

    // Reading order for screen readers: name → fare → ETA → seats.
    return Semantics(
      button: true,
      selected: selected,
      label: l.fareCardSemantic(name, fare, eta, estimate.vehicleType.capacity),
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          decoration: BoxDecoration(
            color: selected ? AppColors.amber50 : AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? AppColors.amber500 : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.amber100
                          : AppColors.neutral100,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Icon(
                      vehicleIcon(estimate.vehicleType),
                      color: selected
                          ? AppColors.amber800
                          : AppColors.neutral700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name, style: AppTypography.headingSm),
                            if (estimate.hasSurge) ...[
                              const SizedBox(width: AppSpacing.sm),
                              StatusPill(
                                label: l.surgeLabel,
                                color: AppColors.warning,
                                background: AppColors.warningSurface,
                                icon: Icons.trending_up_rounded,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l.etaAway(eta)} · ${l.seats(estimate.vehicleType.capacity)}',
                          style: AppTypography.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    fare,
                    style: AppTypography.numeric.copyWith(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Booking-call failure (network/timeout/5xx) — distinct from "no drivers".
class _BookingFailedCard extends StatelessWidget {
  const _BookingFailedCard({
    required this.onRetry,
    required this.onDismiss,
    required this.isRetrying,
  });

  final VoidCallback onRetry;
  final VoidCallback onDismiss;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.bookingFailedTitle,
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
              AppIconButton(
                icon: Icons.close_rounded,
                semanticLabel: l.semanticDismiss,
                color: AppColors.danger,
                onPressed: onDismiss,
              ),
            ],
          ),
          Text(l.bookingFailedBody, style: AppTypography.bodySecondary),
          const SizedBox(height: AppSpacing.sm),
          AppButton.destructive(
            label: l.retry,
            onPressed: onRetry,
            isLoading: isRetrying,
            expand: false,
            compact: true,
          ),
        ],
      ),
    );
  }
}
