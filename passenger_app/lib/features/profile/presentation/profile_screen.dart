import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _privacyUrl = 'https://pothik.app/privacy';
  static const _termsUrl = 'https://pothik.app/terms';

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.logout),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = switch (ref.watch(authControllerProvider)) {
      Authenticated(:final user) => user,
      _ => null,
    };
    final settings = ref.watch(accountSettingsProvider);

    return AppScaffold(
      title: l.profile,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: InkWell(
              onTap: () => context.push(Routes.profileEdit),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    UserAvatar(user: user),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? '',
                            style: AppTypography.headingMd,
                          ),
                          if ((user?.username ?? '').isNotEmpty)
                            Text(
                              '@${user!.username}',
                              style: AppTypography.bodySecondary,
                            ),
                          if (user != null)
                            Text(
                              Formatters.phoneDisplay(user.phone),
                              style: AppTypography.bodySecondary,
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppColors.amber600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${settings.overallRating.toStringAsFixed(1)} · ${settings.tripsCompleted} ${l.tripsCompleted}',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.edit_outlined,
                      semanticLabel: l.editProfile,
                      onPressed: () => context.push(Routes.profileEdit),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          _section(l.profileSectionInfo),
          _tile(
            icon: Icons.person_outline_rounded,
            title: l.editProfile,
            subtitle: l.editProfileHint,
            onTap: () => context.push(Routes.profileEdit),
          ),
          _tile(
            icon: Icons.contact_emergency_rounded,
            title: l.emergencyContacts,
            onTap: () => context.push(Routes.emergencyContacts),
          ),
          _section(l.accountSecurity),
          _tile(
            icon: Icons.security_rounded,
            title: l.accountSecurity,
            onTap: () => context.push(Routes.accountSecurity),
          ),
          _section(l.savedPlaces),
          _tile(
            icon: Icons.bookmark_rounded,
            title: l.savedPlaces,
            subtitle: '${l.placeHome} · ${l.placeWork} · ${l.placeOther}',
            onTap: () => context.push(Routes.places),
          ),
          _section(l.paymentMethods),
          _tile(
            icon: Icons.account_balance_wallet_outlined,
            title: l.paymentMethods,
            subtitle: l.walletBalance(
              Formatters.currency(settings.walletBalance),
            ),
            onTap: () => context.push(Routes.payments),
          ),
          _section(l.rideHistory),
          _tile(
            icon: Icons.history_rounded,
            title: l.rideHistory,
            onTap: () => context.push(Routes.history),
          ),
          _tile(
            icon: Icons.event_available_rounded,
            title: l.scheduledRides,
            onTap: () => context.push(Routes.scheduledRides),
          ),
          _section(l.ratingsReviews),
          _tile(
            icon: Icons.reviews_outlined,
            title: l.ratingsReviews,
            onTap: () => context.push(Routes.ratings),
          ),
          _section(l.promotionsReferrals),
          _tile(
            icon: Icons.card_giftcard_rounded,
            title: l.promotionsReferrals,
            subtitle: '${l.rewardPoints}: ${settings.rewardPoints}',
            onTap: () => context.push(Routes.promotions),
          ),
          _section(l.notificationSettings),
          _tile(
            icon: Icons.notifications_outlined,
            title: l.notificationSettings,
            onTap: () => context.push(Routes.notifications),
          ),
          _section(l.helpSupport),
          _tile(
            icon: Icons.help_outline_rounded,
            title: l.helpSupport,
            onTap: () => context.push(Routes.help),
          ),
          _section(l.appSettings),
          _tile(
            icon: Icons.settings_outlined,
            title: l.appSettings,
            onTap: () => context.push(Routes.appSettings),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.privacyPolicy),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => launchUrl(
              Uri.parse(_privacyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.terms),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => launchUrl(
              Uri.parse(_termsUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton.outline(
              label: l.logout,
              icon: Icons.logout_rounded,
              onPressed: () => _logout(context, ref),
            ),
          ),
          Center(child: Text(l.version('1.0.0'), style: AppTypography.caption)),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    child: Text(title, style: AppTypography.caption),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
