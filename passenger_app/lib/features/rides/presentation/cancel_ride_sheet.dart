import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/buttons.dart';
import '../domain/ride_models.dart';

/// Bottom sheet asking for a cancel reason. Returns `null` if kept.
Future<CancelReason?> showCancelRideSheet(BuildContext context) {
  return showModalBottomSheet<CancelReason>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _CancelSheet(),
  );
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  CancelReason? _reason;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = {
      CancelReason.changedMind: l.cancelReasonChangedMind,
      CancelReason.driverTooFar: l.cancelReasonDriverFar,
      CancelReason.wrongPickup: l.cancelReasonWrongPickup,
      CancelReason.driverAskedToCancel: l.cancelReasonDriverAsked,
      CancelReason.other: l.cancelReasonOther,
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.cancelRideTitle, style: AppTypography.headingMd),
          const SizedBox(height: AppSpacing.xs),
          Text(l.cancelReasonPrompt, style: AppTypography.bodySecondary),
          const SizedBox(height: AppSpacing.md),
          for (final e in labels.entries)
            RadioListTile<CancelReason>(
              value: e.key,
              // ignore: deprecated_member_use
              groupValue: _reason,
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _reason = v),
              title: Text(e.value),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton.destructive(
            label: l.confirmCancel,
            onPressed: _reason == null
                ? null
                : () => Navigator.pop(context, _reason),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.outline(
            label: l.keepRide,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
