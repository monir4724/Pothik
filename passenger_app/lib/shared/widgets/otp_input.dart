import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/generated/app_localizations.dart';

/// Six-box OTP entry backed by a single hidden text field (so paste, SMS
/// autofill and screen readers all work). Boxes shrink on narrow screens
/// and at large font scales instead of overflowing.
class OtpInput extends StatefulWidget {
  const OtpInput({
    required this.onCompleted,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
    this.controller,
    super.key,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final bool hasError;
  final bool enabled;
  final TextEditingController? controller;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _ctrl =
      widget.controller ?? TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: AppMotion.shake,
  );

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(OtpInput old) {
    super.didUpdateWidget(old);
    if (widget.hasError && !old.hasError) {
      if (!AppMotion.reduced(context)) _shake.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  void _onChanged() {
    setState(() {});
    if (_ctrl.text.length == widget.length) {
      widget.onCompleted(_ctrl.text);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    if (widget.controller == null) _ctrl.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = _ctrl.text;
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 6 boxes + 5 gaps must fit; shrink boxes rather than overflow.
        const gap = AppSpacing.sm;
        final available = constraints.maxWidth - gap * (widget.length - 1);
        final box = min(52.0, available / widget.length);
        final boxHeight = max(box, 44.0 * min(scale, 1.6));

        return GestureDetector(
          onTap: widget.enabled ? () => _focus.requestFocus() : null,
          child: Stack(
            children: [
              // Hidden real input.
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 1,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: widget.length,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final dx =
                      sin(_shake.value * pi * 4) * 8 * (1 - _shake.value);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: Semantics(
                  textField: true,
                  label: l.otpTitle,
                  value: text,
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < widget.length; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          _Box(
                            width: box,
                            height: boxHeight,
                            char: i < text.length ? text[i] : '',
                            focused:
                                widget.enabled &&
                                _focus.hasFocus &&
                                i == min(text.length, widget.length - 1),
                            hasError: widget.hasError,
                            semantic: l.otpDigitSemantic(i + 1),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.width,
    required this.height,
    required this.char,
    required this.focused,
    required this.hasError,
    required this.semantic,
  });

  final double width;
  final double height;
  final String char;
  final bool focused;
  final bool hasError;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    final border = hasError
        ? AppColors.danger
        : focused
        ? AppColors.amber600
        : AppColors.border;
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.fast),
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: border, width: focused || hasError ? 2 : 1),
      ),
      child: Text(
        char,
        style: AppTypography.numeric.copyWith(fontSize: 24),
        semanticsLabel: semantic,
      ),
    );
  }
}
