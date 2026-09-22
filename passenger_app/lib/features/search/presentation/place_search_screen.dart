import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/location/location_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/states.dart';
import '../../places/presentation/saved_places_controller.dart';
import '../../rides/domain/ride_models.dart';

enum SearchField { pickup, dropoff }

/// Debounced place search. Returns the chosen [Place] via `pop`.
class PlaceSearchScreen extends ConsumerStatefulWidget {
  const PlaceSearchScreen({required this.field, super.key});

  final SearchField field;

  @override
  ConsumerState<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends ConsumerState<PlaceSearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  AsyncValue<List<Place>> _results = const AsyncValue.data([]);
  int _requestSeq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _results = const AsyncValue.data([]));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final seq = ++_requestSeq;
    setState(() => _results = const AsyncValue.loading());
    try {
      GeoPoint? near;
      try {
        near = await ref.read(locationServiceProvider).current(
          timeout: const Duration(seconds: 2),
        );
      } on Object {
        near = null;
      }
      final r = await ref
          .read(placesRepositoryProvider)
          .search(_query.trim(), near: near);
      if (seq != _requestSeq || !mounted) return; // stale response
      setState(() => _results = AsyncValue.data(r));
    } on Object catch (e, st) {
      if (seq != _requestSeq || !mounted) return;
      setState(() => _results = AsyncValue.error(e, st));
    }
  }

  Future<void> _useCurrent() async {
    final l = AppLocalizations.of(context);
    final p = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    if (p == null) {
      context.showSnack(l.gpsOffTitle);
      return;
    }
    final place =
        await ref.read(placesRepositoryProvider).reverseGeocode(p) ??
        Place(name: l.currentLocation, address: '', lat: p.lat, lng: p.lng);
    if (mounted) context.pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final saved = ref.watch(savedPlacesProvider).value ?? const [];

    return AppScaffold(
      title: widget.field == SearchField.pickup
          ? l.pickupLabel
          : l.dropoffLabel,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.searchPlacesHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : AppIconButton(
                        icon: Icons.close_rounded,
                        semanticLabel: l.semanticClearSearch,
                        onPressed: () {
                          _ctrl.clear();
                          _onChanged('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _query.trim().length < 2
                ? ListView(
                    children: [
                      if (widget.field == SearchField.pickup)
                        ListTile(
                          leading: const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.info,
                          ),
                          title: Text(l.useCurrentLocation),
                          onTap: _useCurrent,
                        ),
                      for (final sp in saved)
                        ListTile(
                          leading: const Icon(Icons.bookmark_rounded),
                          title: Text(sp.label),
                          subtitle: Text(
                            sp.place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => context.pop(sp.place),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          l.searchStartTyping,
                          style: AppTypography.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : _results.when(
                    loading: () => const SkeletonList(count: 5),
                    error: (e, _) => ErrorState(error: e, onRetry: _search),
                    data: (places) => places.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: l.searchNoResults(_query.trim()),
                          )
                        : ListView.separated(
                            itemCount: places.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, i) {
                              final p = places[i];
                              return ListTile(
                                leading: const Icon(Icons.place_outlined),
                                title: Text(p.name),
                                subtitle: Text(
                                  p.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => context.pop(p),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
