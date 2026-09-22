import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/states.dart';
import '../../rides/domain/ride_models.dart';
import '../../rides/presentation/fare_estimate_screen.dart';

/// Cursor-paginated history controller. Never loads the whole history.
final class HistoryState {
  const HistoryState({
    this.items = const [],
    this.nextCursor,
    this.isLoadingFirst = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<RideSummary> items;
  final String? nextCursor;
  final bool isLoadingFirst;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => nextCursor != null;

  HistoryState copyWith({
    List<RideSummary>? items,
    Object? nextCursor = _s,
    bool? isLoadingFirst,
    bool? isLoadingMore,
    Object? error = _s,
  }) => HistoryState(
    items: items ?? this.items,
    nextCursor: nextCursor == _s ? this.nextCursor : nextCursor as String?,
    isLoadingFirst: isLoadingFirst ?? this.isLoadingFirst,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: error == _s ? this.error : error,
  );

  static const _s = Object();
}

final historyProvider =
    NotifierProvider.autoDispose<HistoryController, HistoryState>(
      HistoryController.new,
    );

final class HistoryController extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    Future.microtask(refresh);
    return const HistoryState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirst: state.items.isEmpty, error: null);
    try {
      final page = await ref.read(rideRepositoryProvider).history();
      state = HistoryState(
        items: page.items,
        nextCursor: page.nextCursor,
        isLoadingFirst: false,
      );
    } on Object catch (e) {
      state = state.copyWith(isLoadingFirst: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref
          .read(rideRepositoryProvider)
          .history(cursor: state.nextCursor);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        isLoadingMore: false,
      );
    } on Object catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(historyProvider);
    final locale = Localizations.localeOf(context).toString();

    Widget body;
    if (state.isLoadingFirst) {
      body = const SkeletonList(count: 8);
    } else if (state.error != null && state.items.isEmpty) {
      body = ErrorState(
        error: state.error!,
        onRetry: () => ref.read(historyProvider.notifier).refresh(),
      );
    } else if (state.items.isEmpty) {
      body = EmptyState(
        icon: Icons.history_rounded,
        title: l.historyEmptyTitle,
        body: l.historyEmptyBody,
        actionLabel: l.bookFirstRide,
        onAction: () => context.go(Routes.home),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.read(historyProvider.notifier).refresh(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) {
              ref.read(historyProvider.notifier).loadMore();
            }
            return false;
          },
          child: ListView.separated(
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              if (i >= state.items.length) return const SkeletonListTile();
              final r = state.items[i];
              return _HistoryTile(summary: r, locale: locale);
            },
          ),
        ),
      );
    }

    return AppScaffold(title: l.rideHistory, body: body);
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.summary, required this.locale});

  final RideSummary summary;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (statusLabel, color, bg) = rideStatusStyle(l, summary.status);
    final date = Formatters.dateTime(
      summary.createdAt.toLocal(),
      locale: locale,
    );
    final fare = Formatters.currency(summary.fare);

    return Semantics(
      button: true,
      label: l.historyItemSemantic(
        statusLabel,
        summary.pickupName,
        summary.dropoffName,
        fare,
        date,
      ),
      child: ExcludeSemantics(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.neutral100,
            child: Icon(
              vehicleIcon(summary.vehicleType),
              color: AppColors.neutral700,
            ),
          ),
          title: Text(
            summary.dropoffName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyStrong,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              StatusPill(label: statusLabel, color: color, background: bg),
            ],
          ),
          trailing: Text(
            fare,
            style: AppTypography.bodyStrong.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              decoration: summary.status == RideStatus.cancelled
                  ? TextDecoration.lineThrough
                  : null,
              color: summary.status == RideStatus.cancelled
                  ? AppColors.neutral400
                  : AppColors.textPrimary,
            ),
          ),
          isThreeLine: true,
          onTap: () => context.push(Routes.historyDetail(summary.id)),
        ),
      ),
    );
  }
}

(String, Color, Color) rideStatusStyle(AppLocalizations l, RideStatus s) =>
    switch (s) {
      RideStatus.completed => (
        l.statusCompleted,
        AppColors.success,
        AppColors.successSurface,
      ),
      RideStatus.cancelled => (
        l.statusCancelled,
        AppColors.neutral700,
        AppColors.neutral100,
      ),
      RideStatus.noDriver => (
        l.statusNoDriver,
        AppColors.warning,
        AppColors.warningSurface,
      ),
      _ => (l.statusActive, AppColors.info, AppColors.infoSurface),
    };
