import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/haptics/app_haptics.dart';
import '../../l10n/generated/app_localizations.dart';

/// Five-star input. Each star is a ≥48dp target with a semantic label
/// ("3 of 5 stars"); the tap bounce is skipped under reduce-motion.
class StarRating extends StatelessWidget {
  const StarRating({
    required this.value,
    required this.onChanged,
    this.size = 40,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i <= value,
            label: l.rateStar(i),
            child: ExcludeSemantics(
              child: InkResponse(
                radius: AppSizes.minTapTarget / 2 + 4,
                onTap: () {
                  AppHaptics.light();
                  onChanged(i);
                },
                child: SizedBox.square(
                  dimension: AppSizes.minTapTarget + AppSpacing.sm,
                  child: Center(
                    child: _Star(filled: i <= value, size: size),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.filled, required this.size});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: filled ? 1.0 : 0.9,
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.emphasized,
      child: Icon(
        filled ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: filled ? AppColors.amber500 : AppColors.neutral300,
      ),
    );
  }
}
