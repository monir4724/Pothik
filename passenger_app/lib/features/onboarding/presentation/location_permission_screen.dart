import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/location/location_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';

/// B2.1 plus the two states the base spec collapsed:
/// - permanently denied → Settings deep link (the OS prompt won't show again)
/// - GPS hardware off → device location settings (not an app permission)
///
/// Re-checks automatically when the app returns from Settings.
class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends ConsumerState<LocationPermissionScreen>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheck();
  }

  Future<void> _recheck() async {
    final a = await ref.read(locationAvailabilityProvider.notifier).refresh();
    if (a == LocationAvailability.ready && mounted) context.go(Routes.home);
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    await ref.read(appPreferencesProvider).setLocationRationaleShown();
    final a = await ref.read(locationAvailabilityProvider.notifier).request();
    if (!mounted) return;
    setState(() => _busy = false);
    if (a == LocationAvailability.ready) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final availability =
        ref.watch(locationAvailabilityProvider) ?? LocationAvailability.denied;
    final svc = ref.read(locationServiceProvider);

    final (
      icon,
      title,
      body,
      primaryLabel,
      primaryAction,
    ) = switch (availability) {
      LocationAvailability.permanentlyDenied => (
        Icons.location_disabled_rounded,
        l.locPermDeniedForeverTitle,
        l.locPermDeniedForeverBody,
        l.openSettings,
        () => svc.openAppSettings(),
      ),
      LocationAvailability.serviceDisabled => (
        Icons.gps_off_rounded,
        l.gpsOffTitle,
        l.gpsOffBody,
        l.turnOnLocation,
        () => svc.openLocationSettings(),
      ),
      _ => (
        Icons.location_on_rounded,
        l.locPermTitle,
        l.locPermBody,
        l.allowLocation,
        _request,
      ),
    };
    final needsSettings =
        availability != LocationAvailability.denied &&
        availability != LocationAvailability.ready;

    return AppScaffold(
      showBack: false,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.amber50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.amber700),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              style: AppTypography.headingLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              body,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton.primary(
            label: primaryLabel,
            onPressed: _busy ? null : () => primaryAction(),
            isLoading: _busy,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (needsSettings)
            AppButton.outline(label: l.iveEnabledIt, onPressed: _recheck)
          else
            AppButton.ghost(
              label: l.enterPickupManually,
              onPressed: () => context.go(Routes.home),
            ),
        ],
      ),
    );
  }
}
