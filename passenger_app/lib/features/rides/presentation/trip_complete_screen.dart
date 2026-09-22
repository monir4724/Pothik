import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/states.dart';
import 'active_ride_controller.dart';

/// B4.6 — fare breakdown + cash confirmation. The confirm is idempotent
/// (one key per ride, reused on retry) and has an explicit failure state
/// instead of a stuck button.
class TripCompleteScreen extends ConsumerWidget {
  const TripCompleteScreen({required this.rideId, super.key});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(activeRideProvider);
    final ride = state.ride;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    ref.listen(activeRideProvider.select((s) => s.ride?.cashConfirmed), (
      prev,
      next,
    ) {
      if (next == true && prev != true) {
        context.showSnack(l.paymentConfirmed);
        context.go(Routes.rate(rideId));
      }
    });

    if (ride == null || ride.id != rideId) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final b = ride.breakdown;
    final total = b?.total ?? ride.fare;

    return PopScope(
      canPop: false,
      child: AppScaffold(
        showBack: false,
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.lg),
            const Icon(
              Icons.flag_circle_rounded,
              size: 72,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.tripCompleteTitle,
              style: AppTypography.headingLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ride.dropoff.name,
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (ride.distanceMeters != null &&
                ride.durationSeconds != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${Formatters.distance(ride.distanceMeters!, bn: isBn)} · '
                '${Formatters.duration(ride.durationSeconds!, bn: isBn)}',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.amber50,
                borderRadius: AppRadius.lgAll,
              ),
              child: Column(
                children: [
                  Text(l.totalFare, style: AppTypography.bodySecondary),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Formatters.currency(total),
                    style: AppTypography.numeric.copyWith(fontSize: 40),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.payCash, style: AppTypography.bodyStrong),
                ],
              ),
            ),
            if (b != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _line(l.fareBase, b.base),
                      _line(l.fareDistance, b.distanceCharge),
                      _line(l.fareTime, b.timeCharge),
                      if (b.surgeCharge > 0) _line(l.fareSurge, b.surgeCharge),
                      if (b.discount > 0) _line(l.fareDiscount, -b.discount),
                      const Divider(height: AppSpacing.lg),
                      _line(l.totalFare, b.total, strong: true),
                    ],
                  ),
                ),
              ),
            ],
            if (state.cashConfirmError != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.dangerSurface,
                  borderRadius: AppRadius.lgAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.cashConfirmFailedTitle,
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l.cashConfirmFailedBody,
                      style: AppTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        bottom: AppButton.primary(
          label: state.cashConfirmError != null
              ? l.retry
              : l.confirmCashPaid(Formatters.currency(total)),
          isLoading: state.isConfirmingCash,
          onPressed: () => ref.read(activeRideProvider.notifier).confirmCash(),
        ),
      ),
    );
  }

  Widget _line(String label, num amount, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: strong
                ? AppTypography.bodyStrong
                : AppTypography.bodySecondary,
          ),
        ),
        Text(
          Formatters.currency(amount),
          style: (strong ? AppTypography.bodyStrong : AppTypography.body)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    ),
  );
}
