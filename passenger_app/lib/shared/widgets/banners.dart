import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum BannerTone { neutral, warning, danger, info, success }

/// Thin, full-width status strip (offline, reconnecting, location paused).
/// Announced to screen readers as a live region.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    required this.message,
    this.tone = BannerTone.neutral,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.showSpinner = false,
    super.key,
  });

  final String message;
  final BannerTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BannerTone.neutral => (AppColors.neutral800, AppColors.white),
      BannerTone.warning => (AppColors.warningSurface, AppColors.warning),
      BannerTone.danger => (AppColors.dangerSurface, AppColors.danger),
      BannerTone.info => (AppColors.infoSurface, AppColors.info),
      BannerTone.success => (AppColors.successSurface, AppColors.success),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (showSpinner)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else if (icon != null)
                Icon(icon, size: 18, color: fg),
              if (showSpinner || icon != null)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySecondary.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: fg,
                    minimumSize: const Size(AppSizes.minTapTarget, 36),
                    textStyle: AppTypography.bodySecondary.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slides a banner in/out; instant under reduce-motion.
class AnimatedBannerSlot extends StatelessWidget {
  const AnimatedBannerSlot({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: child ?? const SizedBox(width: double.infinity),
    );
  }
}
