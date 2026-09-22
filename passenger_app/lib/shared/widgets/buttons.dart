import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/haptics/app_haptics.dart';

enum _Variant { primary, secondary, outline, destructive, ghost }

/// The button system (A3), implemented once. Every variant shares
/// pressed / disabled / loading logic, a 52dp default height, a 48dp
/// minimum hit area and text that can wrap for long Bangla strings.
class AppButton extends StatelessWidget {
  const AppButton._({
    required this.label,
    required this.onPressed,
    required _Variant variant,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.compact = false,
    this.semanticLabel,
    super.key,
  }) : _variant = variant; // ignore: prefer_initializing_formals

  const AppButton.primary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expand = true,
    bool compact = false,
    String? semanticLabel,
    Key? key,
  }) : this._(
         label: label,
         onPressed: onPressed,
         variant: _Variant.primary,
         isLoading: isLoading,
         icon: icon,
         expand: expand,
         compact: compact,
         semanticLabel: semanticLabel,
         key: key,
       );

  const AppButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expand = true,
    bool compact = false,
    String? semanticLabel,
    Key? key,
  }) : this._(
         label: label,
         onPressed: onPressed,
         variant: _Variant.secondary,
         isLoading: isLoading,
         icon: icon,
         expand: expand,
         compact: compact,
         semanticLabel: semanticLabel,
         key: key,
       );

  const AppButton.outline({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expand = true,
    bool compact = false,
    String? semanticLabel,
    Key? key,
  }) : this._(
         label: label,
         onPressed: onPressed,
         variant: _Variant.outline,
         isLoading: isLoading,
         icon: icon,
         expand: expand,
         compact: compact,
         semanticLabel: semanticLabel,
         key: key,
       );

  const AppButton.destructive({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expand = true,
    bool compact = false,
    String? semanticLabel,
    Key? key,
  }) : this._(
         label: label,
         onPressed: onPressed,
         variant: _Variant.destructive,
         isLoading: isLoading,
         icon: icon,
         expand: expand,
         compact: compact,
         semanticLabel: semanticLabel,
         key: key,
       );

  const AppButton.ghost({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expand = false,
    bool compact = false,
    String? semanticLabel,
    Key? key,
  }) : this._(
         label: label,
         onPressed: onPressed,
         variant: _Variant.ghost,
         isLoading: isLoading,
         icon: icon,
         expand: expand,
         compact: compact,
         semanticLabel: semanticLabel,
         key: key,
       );

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;
  final bool compact;
  final String? semanticLabel;
  final _Variant _variant;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final height = compact
        ? AppSizes.buttonHeightCompact
        : AppSizes.buttonHeight;
    final (bg, fg, border) = _colors();

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(expand ? double.infinity : AppSizes.minTapTarget, height),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _variant == _Variant.ghost || _variant == _Variant.outline
              ? Colors.transparent
              : AppColors.neutral200;
        }
        if (states.contains(WidgetState.pressed)) return _pressed(bg);
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? AppColors.textDisabled : fg,
      ),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      side: border == null
          ? null
          : WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? AppColors.neutral200
                    : border,
                width: 1.5,
              ),
            ),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: const WidgetStatePropertyAll(AppTypography.button),
      animationDuration: AppMotion.duration(context, AppMotion.fast),
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    final child = AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.fast),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final button = FilledButton(
      style: style,
      onPressed: _enabled
          ? () {
              AppHaptics.light();
              onPressed!();
            }
          : null,
      child: child,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: semanticLabel,
      // Announce busy state to screen readers instead of a silent spinner.
      liveRegion: isLoading,
      child: ExcludeSemantics(excluding: semanticLabel != null, child: button),
    );
  }

  (Color, Color, Color?) _colors() => switch (_variant) {
    _Variant.primary => (AppColors.amber500, AppColors.textOnPrimary, null),
    _Variant.secondary => (AppColors.neutral900, AppColors.white, null),
    _Variant.outline => (
      Colors.transparent,
      AppColors.textPrimary,
      AppColors.neutral300,
    ),
    _Variant.destructive => (AppColors.danger, AppColors.white, null),
    _Variant.ghost => (Colors.transparent, AppColors.textLink, null),
  };

  Color _pressed(Color c) {
    if (c == Colors.transparent) return AppColors.neutral100;
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.07).clamp(0.0, 1.0)).toColor();
  }
}

/// Icon-only control with a guaranteed 48dp hit area and a mandatory
/// semantic label (production a11y §3).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = AppSizes.iconMd,
    this.elevated = false,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  /// Adds a white disc + shadow for use over the map.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (elevated ? AppColors.surface : null);
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      child: ExcludeSemantics(
        child: Material(
          color: bg ?? Colors.transparent,
          shape: const CircleBorder(),
          elevation: elevated ? 3 : 0,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed == null
                ? null
                : () {
                    AppHaptics.light();
                    onPressed!();
                  },
            child: SizedBox.square(
              dimension: AppSizes.minTapTarget,
              child: Center(
                child: Icon(
                  icon,
                  size: size,
                  color: onPressed == null
                      ? AppColors.textDisabled
                      : (color ?? AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
