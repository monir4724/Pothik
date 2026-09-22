import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../../shared/widgets/states.dart';
import 'active_ride_controller.dart';

class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({required this.rideId, super.key});

  final String rideId;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _stars = 0;
  final _comment = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(activeRideProvider.notifier).dismissFinishedRide();
    context.go(Routes.home);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(activeRideProvider.notifier)
          .rate(
            stars: _stars,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
      if (!mounted) return;
      context.showSnack(AppLocalizations.of(context).ratingThanks);
      _finish();
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ride = ref.watch(activeRideProvider.select((s) => s.ride));
    final driverName = ride?.driver?.name ?? l.driverLabel;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _finish(),
      child: AppScaffold(
        showBack: false,
        actions: [AppButton.ghost(label: l.skip, onPressed: _finish)],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.neutral100,
                foregroundImage: ride?.driver?.photoUrl == null
                    ? null
                    : NetworkImage(ride!.driver!.photoUrl!),
                child: const Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: AppColors.neutral500,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.rateTitle,
                style: AppTypography.headingLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.rateSubtitle(driverName),
                style: AppTypography.bodySecondary,
              ),
              const SizedBox(height: AppSpacing.xl),
              StarRating(
                value: _stars,
                onChanged: (v) => setState(() => _stars = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _comment,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(hintText: l.rateCommentHint),
              ),
            ],
          ),
        ),
        bottom: AppButton.primary(
          label: l.submitRating,
          isLoading: _submitting,
          onPressed: _stars == 0 ? null : _submit,
        ),
      ),
    );
  }
}
