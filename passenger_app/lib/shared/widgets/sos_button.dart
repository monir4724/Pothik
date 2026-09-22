import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/haptics/app_haptics.dart';
import '../../l10n/generated/app_localizations.dart';

/// SOS control (A4). Press-and-hold for 3s; a ring fills as progress, with a
/// haptic tick each second. Releasing early cancels. Under reduce-motion the
/// idle pulse is disabled and the ring updates in discrete steps.
///
/// Placement is the caller's job — it must sit inside [SafeArea] so it
/// clears notches / punch-holes.
class SosButton extends StatefulWidget {
  const SosButton({required this.onTriggered, this.size = 56, super.key});

  final VoidCallback onTriggered;
  final double size;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: AppMotion.sosHold,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.pulse,
  );
  Timer? _tick;
  int _secondsLeft = 3;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _hold.addStatusListener((s) {
      if (s == AnimationStatus.completed) _fire();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  void _start() {
    setState(() {
      _holding = true;
      _secondsLeft = 3;
    });
    AppHaptics.tick();
    _hold.forward(from: 0);
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft = (3 - t.tick).clamp(0, 3));
      AppHaptics.tick();
    });
  }

  void _cancel() {
    _tick?.cancel();
    if (_hold.status != AnimationStatus.completed) _hold.reverse();
    if (mounted) setState(() => _holding = false);
  }

  void _fire() {
    _tick?.cancel();
    setState(() => _holding = false);
    _hold.value = 0;
    AppHaptics.alarm();
    widget.onTriggered();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _hold.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reduced = AppMotion.reduced(context);
    final size = widget.size;

    return Semantics(
      button: true,
      label: l.sosSemantic,
      hint: l.sosHoldHint,
      onLongPress: _fire, // screen-reader users get a direct activation path
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: (_) => _start(),
              onLongPressEnd: (_) => _cancel(),
              onLongPressCancel: _cancel,
              onTapDown: (_) => _start(),
              onTapUp: (_) => _cancel(),
              onTapCancel: _cancel,
              child: SizedBox.square(
                dimension: size + 16,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_hold, _pulse]),
                  builder: (context, _) {
                    final pulse = reduced ? 0.0 : _pulse.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!reduced && !_holding)
                          Container(
                            width: size + 16 * pulse,
                            height: size + 16 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.danger.withValues(
                                alpha: 0.35 * (1 - pulse),
                              ),
                            ),
                          ),
                        SizedBox.square(
                          dimension: size + 8,
                          child: CircularProgressIndicator(
                            value: reduced
                                ? (_hold.value * 3).floor() / 3
                                : _hold.value,
                            strokeWidth: 4,
                            color: AppColors.white,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        Container(
                          width: size,
                          height: size,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.danger,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _holding ? '$_secondsLeft' : l.sos,
                            style: AppTypography.button.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: _holding ? 20 : 15,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_holding) ...[
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.neutral900.withValues(alpha: 0.85),
                  borderRadius: AppRadius.smAll,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    l.sosHolding(_secondsLeft),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
