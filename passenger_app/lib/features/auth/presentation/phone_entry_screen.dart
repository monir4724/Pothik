import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/phone.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/states.dart';
import 'auth_controller.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = BdPhone.normalize(_ctrl.text)!;
    setState(() => _submitting = true);
    try {
      final challenge = await ref
          .read(authControllerProvider.notifier)
          .requestOtp(phone);
      if (!mounted) return;
      unawaited(context.push(Routes.otp, extra: challenge));
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final expired = auth is Unauthenticated && auth.sessionExpired;
    final locale = ref.watch(localeProvider);

    return AppScaffold(
      showBack: false,
      actions: [
        TextButton(
          onPressed: () => ref
              .read(localeProvider.notifier)
              .set(
                locale.languageCode == 'bn'
                    ? const Locale('en')
                    : const Locale('bn'),
              ),
          child: Text(
            locale.languageCode == 'bn' ? l.languageEnglish : l.languageBangla,
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: PothikLogo(height: 96, semanticLabel: l.appName)),
              const SizedBox(height: AppSpacing.xl),
              if (expired) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Text(
                    l.errorSessionExpired,
                    style: AppTypography.bodySecondary.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(l.phoneTitle, style: AppTypography.headingLg),
              const SizedBox(height: AppSpacing.sm),
              Text(l.phoneSubtitle, style: AppTypography.bodySecondary),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _ctrl,
                autofocus: true,
                enabled: !_submitting,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s+\-০-৯]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                style: AppTypography.headingMd.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  hintText: l.phoneHint,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.sm,
                    ),
                    child: Text('🇧🇩 +880', style: AppTypography.bodyStrong),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                ),
                validator: (v) =>
                    BdPhone.isValid(v ?? '') ? null : l.phoneInvalid,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: l.sendOtp,
                onPressed: _submit,
                isLoading: _submitting,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.termsNotice,
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
