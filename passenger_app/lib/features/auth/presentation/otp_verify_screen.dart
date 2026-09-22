import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/error_localizer.dart';
import '../../../core/fake/fake_backend.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/otp_input.dart';
import '../../../shared/widgets/states.dart';
import '../domain/user.dart';
import 'auth_controller.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({required this.challenge, super.key});

  final OtpChallenge challenge;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpCtrl = TextEditingController();
  late OtpChallenge _challenge = widget.challenge;
  late Duration _resendIn = _challenge.resendAfter;
  Timer? _timer;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _resendIn = _challenge.resendAfter;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendIn -= const Duration(seconds: 1);
        if (_resendIn <= Duration.zero) {
          _resendIn = Duration.zero;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(phone: _challenge.phone, code: code);
      // Router redirect takes over (profile setup or home).
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorLocalizer.message(AppLocalizations.of(context), e);
      });
      _otpCtrl.clear();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      _challenge = await ref
          .read(authControllerProvider.notifier)
          .requestOtp(_challenge.phone);
      _startCountdown();
      if (mounted) context.showSnack(AppLocalizations.of(context).otpResent);
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canResend = _resendIn == Duration.zero && !_resending;
    final isDev = ref.watch(appConfigProvider).useFakeBackend;

    return AppScaffold(
      title: '',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.otpTitle, style: AppTypography.headingLg),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.otpSubtitle(Formatters.phoneDisplay(_challenge.phone)),
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.xxl),
            OtpInput(
              controller: _otpCtrl,
              hasError: _error != null,
              enabled: !_verifying,
              onCompleted: _verify,
            ),
            const SizedBox(height: AppSpacing.md),
            // Reserve the line so the layout doesn't jump when an error lands.
            SizedBox(
              height: 24,
              child: _error == null
                  ? null
                  : Text(
                      _error!,
                      style: AppTypography.bodySecondary.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
            ),
            if (isDev) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.otpDevHint(FakeWorld.devOtp),
                style: AppTypography.caption,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton.primary(
              label: l.verify,
              isLoading: _verifying,
              onPressed: _otpCtrl.text.length == 6
                  ? () => _verify(_otpCtrl.text)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton.ghost(
                  label: l.otpChangeNumber,
                  onPressed: () => context.pop(),
                ),
                AppButton.ghost(
                  label: canResend
                      ? l.otpResend
                      : l.otpResendIn(Formatters.countdown(_resendIn)),
                  isLoading: _resending,
                  onPressed: canResend ? _resend : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
