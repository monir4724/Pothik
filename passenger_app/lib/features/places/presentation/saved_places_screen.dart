import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/states.dart';
import '../../rides/domain/ride_models.dart';
import '../../rides/presentation/booking_draft_controller.dart';
import '../../search/presentation/place_search_screen.dart';
import '../domain/saved_place.dart';
import 'saved_places_controller.dart';

/// B3.5 — saved places with skeleton loading, empty state, padded delete
/// hit-areas and undo.
class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final place = await context.push<Place>(
      '${Routes.search}?field=${SearchField.dropoff.name}',
    );
    if (place == null || !context.mounted) return;
    final result = await showModalBottomSheet<(SavedPlaceKind, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _KindSheet(placeName: place.name),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(savedPlacesProvider.notifier)
          .add(kind: result.$1, label: result.$2, place: place);
      if (context.mounted) context.showSnack(l.done);
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  void _useAsDestination(BuildContext context, WidgetRef ref, Place place) {
    ref.read(bookingDraftProvider.notifier).setDropoff(place);
    final complete = ref.read(bookingDraftProvider).isComplete;
    context.go(complete ? Routes.estimate : Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final places = ref.watch(savedPlacesProvider);

    return AppScaffold(
      title: l.savedPlaces,
      body: places.when(
        loading: () => const SkeletonList(count: 4),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(savedPlacesProvider),
        ),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.bookmark_add_outlined,
                title: l.savedPlacesEmptyTitle,
                body: l.savedPlacesEmptyBody,
                actionLabel: l.addPlace,
                onAction: () => _add(context, ref),
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final sp = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.neutral100,
                      child: Icon(switch (sp.kind) {
                        SavedPlaceKind.home => Icons.home_rounded,
                        SavedPlaceKind.work => Icons.work_rounded,
                        SavedPlaceKind.other => Icons.star_rounded,
                      }, color: AppColors.neutral700),
                    ),
                    title: Text(sp.label, style: AppTypography.bodyStrong),
                    subtitle: Text(
                      sp.place.address.isEmpty
                          ? sp.place.name
                          : sp.place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: AppIconButton(
                      icon: Icons.delete_outline_rounded,
                      semanticLabel: l.deletePlaceSemantic(sp.label),
                      color: AppColors.neutral500,
                      onPressed: () async {
                        final notifier = ref.read(savedPlacesProvider.notifier);
                        context.showSnack(
                          l.placeDeleted,
                          action: SnackBarAction(
                            label: l.undo,
                            onPressed: () => notifier.restore(sp),
                          ),
                        );
                        try {
                          await notifier.remove(sp.id);
                        } on Object catch (e) {
                          if (context.mounted) context.showError(e);
                        }
                      },
                    ),
                    onTap: () => _useAsDestination(context, ref, sp.place),
                  );
                },
              ),
      ),
      bottom: places.hasValue && (places.value?.isNotEmpty ?? false)
          ? AppButton.primary(
              label: l.addPlace,
              icon: Icons.add_rounded,
              onPressed: () => _add(context, ref),
            )
          : null,
    );
  }
}

class _KindSheet extends StatefulWidget {
  const _KindSheet({required this.placeName});

  final String placeName;

  @override
  State<_KindSheet> createState() => _KindSheetState();
}

class _KindSheetState extends State<_KindSheet> {
  SavedPlaceKind _kind = SavedPlaceKind.home;
  final _label = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kindLabel = {
      SavedPlaceKind.home: l.placeHome,
      SavedPlaceKind.work: l.placeWork,
      SavedPlaceKind.other: l.placeOther,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.placeName, style: AppTypography.headingMd),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final k in SavedPlaceKind.values)
                ChoiceChip(
                  label: Text(kindLabel[k]!),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          if (_kind == SavedPlaceKind.other) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _label,
              autofocus: true,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: l.placeLabelHint,
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: l.save,
            onPressed:
                _kind == SavedPlaceKind.other && _label.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, (
                    _kind,
                    _kind == SavedPlaceKind.other
                        ? _label.text.trim()
                        : kindLabel[_kind]!,
                  )),
          ),
        ],
      ),
    );
  }
}
