import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/logging/app_logger.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/buttons.dart';
import '../data/sos_repository.dart';

const _log = AppLogger('sos');

/// Fires the SOS alert and shows the outcome sheet. The alert request uses
/// one idempotency key for the whole flow so retrying from the failure
/// sheet cannot create a second alert.
Future<void> runSosFlow(
  BuildContext context,
  WidgetRef ref, {
  String? rideId,
}) async {
  final key = const Uuid().v4();
  _log.warn('SOS triggered', {'ride': rideId ?? 'none'});
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => _SosSheet(rideId: rideId, idempotencyKey: key),
  );
}

class _SosSheet extends ConsumerStatefulWidget {
  const _SosSheet({required this.rideId, required this.idempotencyKey});

  final String? rideId;
  final String idempotencyKey;

  @override
  ConsumerState<_SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends ConsumerState<_SosSheet> {
  AsyncValue<SosAlert> _result = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _send();
  }

  Future<void> _send() async {
    setState(() => _result = const AsyncValue.loading());
    try {
      final loc = await ref
          .read(locationServiceProvider)
          .current(timeout: const Duration(seconds: 3));
      final alert = await ref
          .read(sosRepositoryProvider)
          .trigger(
            idempotencyKey: widget.idempotencyKey,
            rideId: widget.rideId,
            location: loc,
          );
      _log.warn('SOS delivered', {'alert': alert.id});
      if (mounted) setState(() => _result = AsyncValue.data(alert));
    } on Object catch (e, st) {
      _log.error('SOS delivery failed', error: e, stackTrace: st);
      if (mounted) setState(() => _result = AsyncValue.error(e, st));
    }
  }

  Future<void> _call999() => launchUrl(Uri(scheme: 'tel', path: '999'));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: _result.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.danger),
          ),
        ),
        data: (alert) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 56,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.sosSentTitle,
              style: AppTypography.headingMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              alert.contactsNotified == 0
                  ? l.sosNoContactsHint
                  : l.sosSentBody(alert.contactsNotified),
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton.destructive(
              label: l.sosCallPolice,
              icon: Icons.call_rounded,
              onPressed: _call999,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.outline(
              label: l.close,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        error: (_, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_rounded, color: AppColors.danger, size: 56),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.sosFailedTitle,
              style: AppTypography.headingMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.sosFailedBody,
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton.destructive(
              label: l.sosCallPolice,
              icon: Icons.call_rounded,
              onPressed: _call999,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.primary(label: l.retry, onPressed: _send),
            const SizedBox(height: AppSpacing.sm),
            AppButton.ghost(
              label: l.close,
              onPressed: () => Navigator.pop(context),
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}
