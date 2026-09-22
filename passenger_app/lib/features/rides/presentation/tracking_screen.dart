import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/banners.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/map_view.dart';
import '../../../shared/widgets/sos_button.dart';
import '../../../shared/widgets/states.dart';
import '../../sos/presentation/sos_flow.dart';
import '../domain/ride_models.dart';
import 'active_ride_controller.dart';
import 'cancel_ride_sheet.dart';

/// Live tracking for accepted → arriving → arrived → in-progress.
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({required this.rideId, super.key});

  final String rideId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with SingleTickerProviderStateMixin {
  PothikMapController? _map;
  late final AnimationController _lerp = AnimationController(
    vsync: this,
    duration: AppMotion.markerInterpolation,
  );
  LatLng? _from;
  LatLng? _to;
  bool _fitted = false;
  bool _cancelling = false;

  @override
  void dispose() {
    _lerp.dispose();
    _map?.dispose();
    super.dispose();
  }

  void _onDriverMoved(DriverLocation loc) {
    final next = LatLng(loc.lat, loc.lng);
    if (_to == next) return;
    _from = _to == null
        ? next
        : LatLng(
            _lerpD(_from!.latitude, _to!.latitude, _lerp.value),
            _lerpD(_from!.longitude, _to!.longitude, _lerp.value),
          );
    _to = next;
    if (AppMotion.reduced(context)) {
      _lerp.value = 1;
    } else {
      _lerp.forward(from: 0);
    }
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;

  LatLng? get _driverPos {
    if (_to == null) return null;
    if (_from == null) return _to;
    return LatLng(
      _lerpD(_from!.latitude, _to!.latitude, _lerp.value),
      _lerpD(_from!.longitude, _to!.longitude, _lerp.value),
    );
  }

  Future<void> _fit(Ride ride) async {
    final c = _map;
    if (c == null || _fitted) return;
    final target = ride.status == RideStatus.inProgress
        ? ride.dropoff
        : ride.pickup;
    final pts = [
      LatLng(target.lat, target.lng),
      if (ride.driverLocation != null)
        LatLng(ride.driverLocation!.lat, ride.driverLocation!.lng),
    ];
    if (pts.length < 2) return;
    _fitted = true;
    final sw = LatLng(
      pts.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
      pts.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
    );
    final ne = LatLng(
      pts.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
      pts.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
    );
    await c.fitBounds(sw, ne);
  }

  Future<void> _cancel() async {
    final reason = await showCancelRideSheet(context);
    if (reason == null || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(activeRideProvider.notifier).cancel(reason);
      if (mounted) {
        context.showSnack(AppLocalizations.of(context).rideCancelled);
        ref.read(activeRideProvider.notifier).dismissFinishedRide();
        context.go(Routes.home);
      }
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(activeRideProvider);
    final ride = state.ride;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    ref.listen(activeRideProvider.select((s) => s.ride?.driverLocation), (
      _,
      loc,
    ) {
      if (loc != null) _onDriverMoved(loc);
    });
    ref.listen(activeRideProvider.select((s) => s.ride?.status), (prev, next) {
      if (next == null || ride == null) return;
      if (prev != next) _fitted = false;
    });

    if (ride == null || ride.id != widget.rideId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (ride.driverLocation != null && _to == null) {
      _onDriverMoved(ride.driverLocation!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fit(ride));

    final size = MediaQuery.sizeOf(context);
    final sheetFraction = (0.42 * 760 / size.height).clamp(0.36, 0.55);
    final target = ride.status == RideStatus.inProgress
        ? ride.dropoff
        : ride.pickup;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _lerp,
            builder: (context, _) {
              final d = _driverPos;
              return MapView(
                initialTarget: LatLng(target.lat, target.lng),
                padding: EdgeInsets.only(bottom: size.height * sheetFraction),
                onMapCreated: (c) {
                  _map = c;
                  _fit(ride);
                },
                markers: {
                  if (ride.status == RideStatus.inProgress)
                    MapMarkers.dropoff(
                      LatLng(ride.dropoff.lat, ride.dropoff.lng),
                    )
                  else
                    MapMarkers.pickup(LatLng(ride.pickup.lat, ride.pickup.lng)),
                  if (d != null)
                    MapMarkers.driver(d, bearing: ride.driverLocation?.bearing),
                },
              );
            },
          ),
          // Top layer: back/status left, SOS right — all inside SafeArea so
          // the SOS clears notches and punch-hole cameras.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: l.semanticBack,
                        elevated: true,
                        onPressed: () => context.go(Routes.home),
                      ),
                      const Spacer(),
                      SosButton(
                        onTriggered: () =>
                            runSosFlow(context, ref, rideId: ride.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.isResyncing)
                    StatusBanner(
                      message: l.resyncing,
                      showSpinner: true,
                      tone: BannerTone.info,
                    )
                  else if (state.locationPaused)
                    StatusBanner(
                      message: l.locationPausedBanner,
                      tone: BannerTone.warning,
                      icon: Icons.location_off_rounded,
                      actionLabel: l.locationPausedAction,
                      onAction: () async {
                        await ref
                            .read(locationServiceProvider)
                            .openAppSettings();
                        await ref
                            .read(activeRideProvider.notifier)
                            .recheckLocation();
                      },
                    )
                  else if (ride.driverLocation?.isStale ?? false)
                    StatusBanner(
                      message: l.driverLocationStale,
                      tone: BannerTone.warning,
                      icon: Icons
                          .signal_wifi_statusbar_connected_no_internet_4_rounded,
                    ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: sheetFraction,
            minChildSize: sheetFraction,
            maxChildSize: 0.9,
            snap: true,
            builder: (context, scroll) => _TripSheet(
              scroll: scroll,
              ride: ride,
              isBn: isBn,
              cancelling: _cancelling,
              onCancel: _cancel,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripSheet extends ConsumerWidget {
  const _TripSheet({
    required this.scroll,
    required this.ride,
    required this.isBn,
    required this.cancelling,
    required this.onCancel,
  });

  final ScrollController scroll;
  final Ride ride;
  final bool isBn;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final driver = ride.driver;
    final loc = ride.driverLocation;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final headline = switch (ride.status) {
      RideStatus.accepted => l.driverOnTheWay,
      RideStatus.arriving => l.driverArriving,
      RideStatus.arrived => l.driverArrived,
      RideStatus.inProgress => l.tripInProgress,
      _ => '',
    };
    final eta = loc?.etaSeconds == null
        ? null
        : '${Formatters.duration(loc!.etaSeconds!, bn: isBn)}'
              '${loc.distanceMeters == null ? '' : ' · ${Formatters.distance(loc.distanceMeters!, bn: isBn)}'}';

    return Material(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: Colors.black26,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(headline, style: AppTypography.headingMd),
                  ),
                  if (eta != null)
                    Text(
                      eta,
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.amber800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (ride.status != RideStatus.inProgress && ride.otp != null)
                _OtpCard(otp: ride.otp!),
              if (driver != null) ...[
                const SizedBox(height: AppSpacing.md),
                _DriverCard(driver: driver, vehicleType: ride.vehicleType),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: l.chat,
                      icon: Icons.chat_bubble_outline_rounded,
                      semanticLabel: l.openChat,
                      onPressed: () => context.push(Routes.chat(ride.id)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.outline(
                      label: l.shareTrip,
                      icon: Icons.share_rounded,
                      onPressed: () => _showShareSheet(context, ref, ride.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _RouteLine(pickup: ride.pickup, dropoff: ride.dropoff),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.estimatedFare, style: AppTypography.bodySecondary),
                  Text(
                    Formatters.currency(ride.fare),
                    style: AppTypography.numeric.copyWith(fontSize: 20),
                  ),
                ],
              ),
              if (ride.status.isCancellableByPassenger) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton.ghost(
                  label: l.cancelRide,
                  onPressed: cancelling ? null : onCancel,
                  isLoading: cancelling,
                  expand: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpCard extends StatelessWidget {
  const _OtpCard({required this.otp});

  final String otp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: '${l.yourOtp}: ${otp.split('').join(' ')}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.amber50,
            borderRadius: AppRadius.lgAll,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.amber200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.yourOtp, style: AppTypography.bodyStrong),
                    const SizedBox(height: 2),
                    Text(l.otpExplain, style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                otp.split('').join(' '),
                style: AppTypography.numeric.copyWith(
                  color: AppColors.amber800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver, required this.vehicleType});

  final Driver driver;
  final VehicleType vehicleType;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.driverCardSemantic(
        driver.name,
        Formatters.rating(driver.rating),
        driver.vehicleModel,
        driver.vehiclePlate,
      ),
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.neutral100,
                  foregroundImage: driver.photoUrl == null
                      ? null
                      : NetworkImage(driver.photoUrl!),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: AppTypography.headingSm),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.amber600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            Formatters.rating(driver.rating),
                            style: AppTypography.bodySecondary,
                          ),
                          if (driver.totalTrips != null) ...[
                            const Text(
                              ' · ',
                              style: AppTypography.bodySecondary,
                            ),
                            Text(
                              l.driverTrips(driver.totalTrips!),
                              style: AppTypography.bodySecondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      driver.vehiclePlate,
                      style: AppTypography.bodyStrong,
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      [
                        driver.vehicleColor,
                        driver.vehicleModel,
                      ].whereType<String>().join(' '),
                      style: AppTypography.caption,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.pickup, required this.dropoff});

  final Place pickup;
  final Place dropoff;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(Icons.trip_origin_rounded, AppColors.pickupMarker, pickup.name),
        const SizedBox(height: AppSpacing.sm),
        _row(Icons.location_on_rounded, AppColors.dropoffMarker, dropoff.name),
      ],
    );
  }

  Widget _row(IconData icon, Color color, String text) => Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          style: AppTypography.bodySecondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Future<void> _showShareSheet(
  BuildContext context,
  WidgetRef ref,
  String rideId,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (_) => _ShareSheet(rideId: rideId),
  );
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.rideId});

  final String rideId;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  AsyncValue<ShareLink> _link = const AsyncValue.loading();
  bool _revoking = false;

  @override
  void initState() {
    super.initState();
    _create();
  }

  Future<void> _create() async {
    setState(() => _link = const AsyncValue.loading());
    try {
      final link = await ref
          .read(rideRepositoryProvider)
          .createShareLink(widget.rideId);
      if (mounted) setState(() => _link = AsyncValue.data(link));
    } on Object catch (e, st) {
      if (mounted) setState(() => _link = AsyncValue.error(e, st));
    }
  }

  Future<void> _revoke() async {
    setState(() => _revoking = true);
    try {
      await ref.read(rideRepositoryProvider).revokeShareLink(widget.rideId);
      if (mounted) {
        context.showSnack(AppLocalizations.of(context).sharingStopped);
        Navigator.pop(context);
      }
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _revoking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.shareTripTitle, style: AppTypography.headingMd),
          const SizedBox(height: AppSpacing.sm),
          _link.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorState(error: e, onRetry: _create),
            data: (link) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.shareTripBody(
                    Formatters.time(link.expiresAt.toLocal(), locale: locale),
                  ),
                  style: AppTypography.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                SelectableText(
                  link.url,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLink,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: l.shareLink,
                  icon: Icons.share_rounded,
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: link.url, subject: l.shareTripTitle),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        label: l.copyLink,
                        icon: Icons.copy_rounded,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: link.url),
                          );
                          if (context.mounted) context.showSnack(l.linkCopied);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.destructive(
                        label: l.stopSharing,
                        onPressed: _revoke,
                        isLoading: _revoking,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
