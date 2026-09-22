import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/fake/fake_backend.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/phone.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/states.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/account_settings.dart';

class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(accountSettingsProvider);

    return AppScaffold(
      title: l.accountSecurity,
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: Text(l.changePassword),
            subtitle: Text(l.changePasswordBody),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final pin = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  final c = TextEditingController();
                  return AlertDialog(
                    title: Text(l.setPin),
                    content: TextField(
                      controller: c,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: InputDecoration(hintText: '••••'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, c.text.trim()),
                        child: Text(l.save),
                      ),
                    ],
                  );
                },
              );
              if (pin == null || pin.length < 4 || !context.mounted) return;
              context.showSnack(l.pinSaved);
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_android_rounded),
            title: Text(l.changePhone),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.changePhone),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(l.linkedAccounts, style: AppTypography.caption),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.g_mobiledata_rounded),
            title: Text(l.linkGoogle),
            subtitle: Text(settings.googleLinked ? l.linked : l.notLinked),
            value: settings.googleLinked,
            onChanged: (v) => ref
                .read(accountSettingsProvider.notifier)
                .save(settings.copyWith(googleLinked: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.facebook_rounded),
            title: Text(l.linkFacebook),
            subtitle: Text(settings.facebookLinked ? l.linked : l.notLinked),
            value: settings.facebookLinked,
            onChanged: (v) => ref
                .read(accountSettingsProvider.notifier)
                .save(settings.copyWith(facebookLinked: v)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.devices_rounded),
            title: Text(l.activeSessions),
            subtitle: Text('${l.thisDevice} · ${l.sessionCurrent}'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.verified_user_outlined),
            title: Text(l.twoFactor),
            subtitle: Text(l.twoFactorBody),
            value: settings.twoFactor,
            onChanged: (v) => ref
                .read(accountSettingsProvider.notifier)
                .save(settings.copyWith(twoFactor: v)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
            title: Text(
              l.deleteAccount,
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.deleteAccountTitle),
                  content: Text(l.deleteAccountBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.deleteAccountConfirm),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (context.mounted) context.showSnack(l.accountDeleted);
            },
          ),
        ],
      ),
    );
  }
}

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final normalized = BdPhone.normalize(_phone.text);
    if (normalized == null) {
      context.showSnack(l.phoneInvalid);
      return;
    }
    if (_otp.text.trim().length < 4) {
      context.showSnack(l.otpInvalid);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).changePhone(
        phone: normalized,
        code: _otp.text.trim(),
      );
      if (!mounted) return;
      context.showSnack(l.phoneChanged);
      context.pop();
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppScaffold(
      title: l.changePhone,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l.changePhoneBody(FakeWorld.testOtp),
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l.newPhoneLabel,
              hintText: l.phoneHint,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.otpLabel),
          ),
        ],
      ),
      bottom: AppButton.primary(
        label: l.save,
        isLoading: _saving,
        onPressed: _save,
      ),
    );
  }
}

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  String _label(AppLocalizations l, PaymentKind k) => switch (k) {
    PaymentKind.cash => l.payCash,
    PaymentKind.bkash => l.payBkash,
    PaymentKind.nagad => l.payNagad,
    PaymentKind.rocket => l.payRocket,
    PaymentKind.card => l.payCard,
    PaymentKind.wallet => l.payWallet,
  };

  IconData _icon(PaymentKind k) => switch (k) {
    PaymentKind.cash => Icons.payments_outlined,
    PaymentKind.bkash || PaymentKind.nagad || PaymentKind.rocket =>
      Icons.phone_android_rounded,
    PaymentKind.card => Icons.credit_card_rounded,
    PaymentKind.wallet => Icons.account_balance_wallet_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(accountSettingsProvider);

    return AppScaffold(
      title: l.paymentMethods,
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: Text(l.wallet),
            subtitle: Text(
              l.walletBalance(Formatters.currency(settings.walletBalance)),
            ),
            trailing: TextButton(
              onPressed: () async {
                await ref.read(accountSettingsProvider.notifier).save(
                  settings.copyWith(
                    walletBalance: settings.walletBalance + 500,
                  ),
                );
                if (context.mounted) context.showSnack(l.topUpDone);
              },
              child: Text(l.topUp),
            ),
          ),
          const Divider(),
          for (final m in settings.methods)
            ListTile(
              leading: Icon(_icon(m.kind)),
              title: Text(m.label.isEmpty ? _label(l, m.kind) : m.label),
              subtitle: Text(
                [
                  if (m.detail != null) m.detail,
                  if (m.isDefault) l.defaultPayment,
                ].whereType<String>().join(' · '),
              ),
              trailing: m.isDefault
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : TextButton(
                      onPressed: () {
                        final next = settings.methods
                            .map(
                              (x) => x.copyWith(isDefault: x.id == m.id),
                            )
                            .toList();
                        ref.read(accountSettingsProvider.notifier).save(
                          settings.copyWith(
                            methods: next,
                            defaultPayment: m.kind,
                          ),
                        );
                      },
                      child: Text(l.setDefault),
                    ),
            ),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: Text(l.addPaymentMethod),
            onTap: () async {
              final kind = await showModalBottomSheet<PaymentKind>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final k in PaymentKind.values)
                        if (k != PaymentKind.cash)
                          ListTile(
                            title: Text(_label(l, k)),
                            onTap: () => Navigator.pop(ctx, k),
                          ),
                    ],
                  ),
                ),
              );
              if (kind == null) return;
              final next = [
                ...settings.methods,
                SavedPaymentMethod(
                  id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
                  kind: kind,
                  label: _label(l, kind),
                  detail: kind == PaymentKind.card ? '•••• 4242' : null,
                ),
              ];
              await ref
                  .read(accountSettingsProvider.notifier)
                  .save(settings.copyWith(methods: next));
              if (context.mounted) context.showSnack(l.paymentAdded);
            },
          ),
        ],
      ),
    );
  }
}

class RatingsReviewsScreen extends ConsumerWidget {
  const RatingsReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(accountSettingsProvider);

    return AppScaffold(
      title: l.ratingsReviews,
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.star_rounded, color: AppColors.amber600),
            title: Text(l.myRating),
            trailing: Text(
              settings.overallRating.toStringAsFixed(1),
              style: AppTypography.headingMd,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.route_rounded),
            title: Text(l.tripsCompleted),
            trailing: Text('${settings.tripsCompleted}'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l.reviewsIGave, style: AppTypography.bodyStrong),
          ),
          if (settings.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l.noReviewsYet, style: AppTypography.bodySecondary),
            )
          else
            for (final r in settings.reviews)
              ListTile(
                title: Text(r.driverName),
                subtitle: Text(
                  [
                    '★' * r.stars,
                    if (r.comment != null) r.comment,
                  ].join(' · '),
                ),
              ),
        ],
      ),
    );
  }
}

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  final _promo = TextEditingController();

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(accountSettingsProvider);

    return AppScaffold(
      title: l.promotionsReferrals,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(l.promoCode, style: AppTypography.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promo,
                  decoration: InputDecoration(hintText: l.promoHint),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                label: l.applyPromo,
                expand: false,
                onPressed: () async {
                  final code = _promo.text.trim().toUpperCase();
                  if (code.isEmpty) return;
                  final promos = {...settings.promos, code}.toList();
                  await ref.read(accountSettingsProvider.notifier).save(
                    settings.copyWith(
                      promos: promos,
                      rewardPoints: settings.rewardPoints + 50,
                    ),
                  );
                  if (context.mounted) context.showSnack(l.promoApplied);
                  _promo.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l.activeCoupons, style: AppTypography.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          if (settings.promos.isEmpty)
            Text(l.noCoupons, style: AppTypography.bodySecondary)
          else
            for (final p in settings.promos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_offer_outlined),
                title: Text(p),
              ),
          const SizedBox(height: AppSpacing.xl),
          Text(l.referralCode, style: AppTypography.bodyStrong),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(settings.referralCode, style: AppTypography.headingMd),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: settings.referralCode),
                );
                if (context.mounted) context.showSnack(l.referralCopied);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l.rewardPoints, style: AppTypography.bodyStrong),
          Text(
            '${settings.rewardPoints}',
            style: AppTypography.headingLg,
          ),
          Text(l.rewardHistory, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(accountSettingsProvider);
    final n = ref.read(accountSettingsProvider.notifier);

    return AppScaffold(
      title: l.notificationSettings,
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l.notifRide),
            value: settings.notifRide,
            onChanged: (v) => n.save(settings.copyWith(notifRide: v)),
          ),
          SwitchListTile(
            title: Text(l.notifPromo),
            value: settings.notifPromo,
            onChanged: (v) => n.save(settings.copyWith(notifPromo: v)),
          ),
          SwitchListTile(
            title: Text(l.notifSms),
            value: settings.notifSms,
            onChanged: (v) => n.save(settings.copyWith(notifSms: v)),
          ),
          SwitchListTile(
            title: Text(l.notifEmail),
            value: settings.notifEmail,
            onChanged: (v) => n.save(settings.copyWith(notifEmail: v)),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppScaffold(
      title: l.helpSupport,
      body: ListView(
        children: [
          for (final item in [
            (Icons.report_problem_outlined, l.reportProblem),
            (Icons.luggage_outlined, l.lostItem),
            (Icons.chat_bubble_outline_rounded, l.liveChat),
            (Icons.help_outline_rounded, l.faq),
          ])
            ListTile(
              leading: Icon(item.$1),
              title: Text(item.$2),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.showSnack(l.supportSubmitted),
            ),
          ListTile(
            leading: const Icon(Icons.call_rounded),
            title: Text(l.callSupport),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => launchUrl(Uri.parse('tel:09678000123')),
          ),
        ],
      ),
    );
  }
}

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(accountSettingsProvider);
    final n = ref.read(accountSettingsProvider.notifier);

    return AppScaffold(
      title: l.appSettings,
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(l.language),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'bn', label: Text(l.languageBangla)),
                ButtonSegment(value: 'en', label: Text(l.languageEnglish)),
              ],
              selected: {locale.languageCode},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  ref.read(localeProvider.notifier).set(Locale(s.first)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l.themeMode),
            subtitle: Text(
              settings.themeMode == 'dark' ? l.darkMode : l.lightMode,
            ),
            trailing: Switch(
              value: settings.themeMode == 'dark',
              onChanged: (v) => n.save(
                settings.copyWith(themeMode: v ? 'dark' : 'light'),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(l.mapType),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'normal', label: Text(l.mapNormal)),
                ButtonSegment(
                  value: 'satellite',
                  label: Text(l.mapSatellite),
                ),
                ButtonSegment(value: 'terrain', label: Text(l.mapTerrain)),
              ],
              selected: {settings.mapType},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  n.save(settings.copyWith(mapType: s.first)),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(l.accessibility, style: AppTypography.caption),
          ),
          SwitchListTile(
            title: Text(l.largeText),
            value: settings.accessibilityLargeText,
            onChanged: (v) =>
                n.save(settings.copyWith(accessibilityLargeText: v)),
          ),
        ],
      ),
    );
  }
}

class ScheduledRidesScreen extends StatelessWidget {
  const ScheduledRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppScaffold(
      title: l.scheduledRides,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            l.noScheduledRides,
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
