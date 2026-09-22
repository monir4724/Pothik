import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/brand.dart';

/// Shown only while auth/ride state is being restored. The router moves on
/// as soon as restore completes, so there is no fixed minimum duration.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reduced = AppMotion.reduced(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: reduced ? 1 : 0.92, end: 1),
          duration: AppMotion.duration(context, AppMotion.slow),
          curve: AppMotion.emphasized,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PothikLogo(height: 128, semanticLabel: l.appName),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.brandGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
