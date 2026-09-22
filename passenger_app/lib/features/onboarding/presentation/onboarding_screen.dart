import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/buttons.dart';

/// Language pick + 3 value pages. Back navigation works between pages; the
/// page index survives rotation/interruption via [PageStorageKey].
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _icons = [
    Icons.two_wheeler_rounded,
    Icons.my_location_rounded,
    Icons.health_and_safety_rounded,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(appPreferencesProvider).setOnboardingDone();
    if (mounted) context.go(Routes.phone);
  }

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final titles = [l.onboardingTitle1, l.onboardingTitle2, l.onboardingTitle3];
    final bodies = [l.onboardingBody1, l.onboardingBody2, l.onboardingBody3];

    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _controller.previousPage(
            duration: AppMotion.duration(context, AppMotion.normal),
            curve: AppMotion.standard,
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    _LanguageToggle(
                      current: locale,
                      onChanged: (loc) =>
                          ref.read(localeProvider.notifier).set(loc),
                    ),
                    const Spacer(),
                    PothikAppMark(size: 36, semanticLabel: l.appName),
                    const Spacer(),
                    if (_page < 2)
                      AppButton.ghost(label: l.skip, onPressed: _finish)
                    else
                      const SizedBox(width: 64),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  key: const PageStorageKey('onboarding'),
                  controller: _controller,
                  itemCount: 3,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) =>
                      _Page(icon: _icons[i], title: titles[i], body: bodies[i]),
                ),
              ),
              Semantics(
                label: l.onboardingPageSemantic(_page + 1, 3),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: AppMotion.duration(context, AppMotion.fast),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.amber500
                                : AppColors.neutral300,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppButton.primary(
                  label: _page == 2 ? l.getStarted : l.continueLabel,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.amber50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: AppColors.amber700),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            style: AppTypography.headingLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.current, required this.onChanged});

  final Locale current;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.chooseLanguage,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'bn', label: Text(l.languageBangla)),
          ButtonSegment(value: 'en', label: Text(l.languageEnglish)),
        ],
        selected: {current.languageCode},
        onSelectionChanged: (s) => onChanged(Locale(s.first)),
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(AppTypography.bodySecondary),
          minimumSize: WidgetStatePropertyAll(Size(0, 40)),
        ),
      ),
    );
  }
}
