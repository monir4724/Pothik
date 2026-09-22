import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/connectivity/connectivity_status.dart';
import '../../core/realtime/realtime_client.dart';
import '../../l10n/generated/app_localizations.dart';
import 'banners.dart';
import 'buttons.dart';

/// Scaffold that owns the system banners (offline / reconnecting) and
/// constrains content width on tablets so cards don't stretch.
class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.showBack = true,
    this.bottom,
    this.constrainWidth = true,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
    this.showConnectivityBanners = true,
    super.key,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;

  /// Pinned to the bottom, above the safe area (CTAs).
  final Widget? bottom;
  final bool constrainWidth;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;
  final bool showConnectivityBanners;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final network = ref.watch(networkStatusProvider).value;
    final realtime = ref.watch(realtimeStatusProvider).value;

    Widget? banner;
    if (showConnectivityBanners) {
      if (network == NetworkStatus.offline) {
        banner = StatusBanner(
          message: l.offlineBanner,
          icon: Icons.wifi_off_rounded,
        );
      } else if (realtime == RealtimeStatus.reconnecting) {
        banner = StatusBanner(
          message: l.reconnectingBanner,
          showSpinner: true,
          tone: BannerTone.warning,
        );
      }
    }

    final canPop = Navigator.of(context).canPop();
    final content = constrainWidth
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
              ),
              child: body,
            ),
          )
        : body;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title == null && leading == null && actions == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              leading:
                  leading ??
                  (showBack && canPop
                      ? AppIconButton(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: l.semanticBack,
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      : null),
              automaticallyImplyLeading: false,
              actions: actions,
            ),
      body: Column(
        children: [
          AnimatedBannerSlot(child: banner),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: constrainWidth
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSizes.maxContentWidth,
                        ),
                        child: bottom,
                      ),
                    )
                  : bottom!,
            ),
    );
  }
}
