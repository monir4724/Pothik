import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/states.dart';
import '../domain/ride_models.dart';
import 'active_ride_controller.dart';
import 'cancel_ride_sheet.dart';
import 'fare_estimate_screen.dart';

/// B4.1. Three states: searching (<90s), taking-longer (≥90s, still
/// searching — cancel is emphasised), and no-driver (terminal — retry or
/// change vehicle). Navigation to tracking is driven by ride status.
class FindingDriverScreen extends ConsumerStatefulWidget {
  const FindingDriverScreen({required this.rideId, super.key});

  final String rideId;

  @override
  ConsumerState<FindingDriverScreen> createState() =>
      _FindingDriverScreenState();
}

class _FindingDriverScreenState extends ConsumerState<FindingDriverScreen> {
  static const _longWait = Duration(seconds: 90);
  Timer? _tick;
  Duration _elapsed = Duration.zero;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final ride = ref.read(activeRideProvider).ride;
      if (ride == null || !mounted) return;
      setState(() {
        _elapsed = DateTime.now().toUtc().difference(ride.createdAt.toUtc());
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    // PopScope can fire while the navigator is still locked — defer the
    // sheet so we never call showModalBottomSheet mid-pop.
    await Future<void>.delayed(Duration.zero);
    if (!mounted || _cancelling) return;
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

    if (ride == null || ride.id != widget.rideId) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (ride.status == RideStatus.noDriver) {
      return _NoDriverView(
        ride: ride,
        onRetry: () {
          ref.read(activeRideProvider.notifier).dismissFinishedRide();
          context.go(Routes.estimate);
        },
        onHome: () {
          ref.read(activeRideProvider.notifier).dismissFinishedRide();
          context.go(Routes.home);
        },
      );
    }

    final longWait = _elapsed >= _longWait;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _cancel(),
      child: AppScaffold(
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _Radar(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                l.findingDriver,
                style: AppTypography.headingLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.normal),
                child: Text(
                  longWait ? l.findingTakingLonger : l.findingDriverBody,
                  key: ValueKey(longWait),
                  style: AppTypography.body.copyWith(
                    color: longWait
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                Formatters.countdown(_elapsed),
                style: AppTypography.numeric.copyWith(
                  color: AppColors.neutral500,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: ListTile(
                  leading: Icon(vehicleIcon(ride.vehicleType)),
                  title: Text(
                    ride.dropoff.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${vehicleLabel(l, ride.vehicleType)} · ${l.estimatedFare}',
                  ),
                  trailing: Text(
                    Formatters.currency(ride.fare),
                    style: AppTypography.numeric.copyWith(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: longWait
            ? AppButton.destructive(
                label: l.cancelRide,
                onPressed: _cancel,
                isLoading: _cancelling,
              )
            : AppButton.outline(
                label: l.cancelRide,
                onPressed: _cancel,
                isLoading: _cancelling,
              ),
      ),
    );
  }
}

class _Radar extends StatefulWidget {
  const _Radar();

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return SizedBox.square(
      dimension: 180,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              if (!reduced)
                _ring(((_c.value + i / 3) % 1.0))
              else
                _ring(0.3 + i * 0.3, opacity: 0.25),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.amber500,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.neutral900,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double t, {double? opacity}) => Container(
    width: 72 + 108 * t,
    height: 72 + 108 * t,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.amber500.withValues(alpha: opacity ?? (1 - t) * 0.6),
        width: 2,
      ),
    ),
  );
}

class _NoDriverView extends StatelessWidget {
  const _NoDriverView({
    required this.ride,
    required this.onRetry,
    required this.onHome,
  });

  final Ride ride;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppScaffold(
      body: EmptyState(
        icon: Icons.no_transfer_rounded,
        title: l.noDriverTitle,
        body: l.noDriverBody,
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton.primary(label: l.tryAgain, onPressed: onRetry),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(label: l.close, onPressed: onHome),
        ],
      ),
    );
  }
}
