import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/providers.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/location/location_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/banners.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/map_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../places/domain/saved_place.dart';
import '../../places/presentation/saved_places_controller.dart';
import '../../rides/domain/ride_models.dart';
import '../../rides/presentation/active_ride_controller.dart';
import '../../rides/presentation/booking_draft_controller.dart';
import '../../search/presentation/place_search_screen.dart';

/// Home shell: full-bleed map, floating hamburger + my-location, and a
/// draggable bottom sheet (initial ~32% height; min-clamped so a 360dp
/// phone still shows the search row + one saved-place row).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  PothikMapController? _map;
  GeoPoint? _me;
  bool _locating = true;
  Timer? _reverseDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  Future<void> _locate() async {
    final availability =
        ref.read(locationAvailabilityProvider) ??
        await ref.read(locationAvailabilityProvider.notifier).refresh();
    if (availability != LocationAvailability.ready) {
      if (mounted) setState(() => _locating = false);
      return;
    }
    final p = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() {
      _me = p;
      _locating = false;
    });
    if (p != null) {
      unawaited(_map?.animateTo(LatLng(p.lat, p.lng)));
      if (ref.read(bookingDraftProvider).pickup == null) {
        _setPickupFromPoint(p);
      }
    }
  }

  void _setPickupFromPoint(GeoPoint p) {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 400), () async {
      final l = AppLocalizations.of(context);
      final place = await ref.read(placesRepositoryProvider).reverseGeocode(p);
      if (!mounted) return;
      ref
          .read(bookingDraftProvider.notifier)
          .setPickup(
            place ??
                Place(
                  name: l.currentLocation,
                  address: '',
                  lat: p.lat,
                  lng: p.lng,
                ),
          );
    });
  }

  Future<void> _pick(SearchField field) async {
    final place = await context.push<Place>(
      '${Routes.search}?field=${field.name}',
    );
    if (place == null || !mounted) return;
    final draft = ref.read(bookingDraftProvider.notifier);
    if (field == SearchField.pickup) {
      draft.setPickup(place);
    } else {
      draft.setDropoff(place);
    }
    _maybeGoToEstimate();
  }

  void _maybeGoToEstimate() {
    final draft = ref.read(bookingDraftProvider);
    if (draft.isComplete) context.push(Routes.estimate);
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = ref.watch(bookingDraftProvider);
    final active = ref.watch(activeRideProvider);
    final availability = ref.watch(locationAvailabilityProvider);
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Keep the sheet usable on very short screens.
    final initialFraction =
        (AppSizes.homeSheetInitialFraction * 760 / size.height).clamp(
          0.30,
          0.45,
        );

    final markers = <Marker>{
      if (draft.pickup != null)
        MapMarkers.pickup(LatLng(draft.pickup!.lat, draft.pickup!.lng)),
    };

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          MapView(
            initialTarget: _me == null
                ? kDhakaCenter
                : LatLng(_me!.lat, _me!.lng),
            markers: markers,
            myLocationEnabled: availability == LocationAvailability.ready,
            padding: EdgeInsets.only(bottom: size.height * initialFraction),
            onMapCreated: (c) => _map = c,
          ),
          // Top controls: inside SafeArea so they clear notches/punch-holes.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppIconButton(
                    icon: Icons.menu_rounded,
                    semanticLabel: l.semanticMenu,
                    elevated: true,
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  AppIconButton(
                    icon: Icons.my_location_rounded,
                    semanticLabel: l.semanticMyLocation,
                    elevated: true,
                    onPressed: _locating ? null : _locate,
                  ),
                ],
              ),
            ),
          ),
          if (active.hasActiveRide)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 72),
                child: StatusBanner(
                  message: l.resumeRideBanner,
                  tone: BannerTone.info,
                  icon: Icons.directions_car_rounded,
                  actionLabel: l.viewRide,
                  onAction: () => context.go(Routes.ride(active.ride!.id)),
                ),
              ),
            ),
          DraggableScrollableSheet(
            initialChildSize: initialFraction,
            minChildSize: initialFraction,
            maxChildSize: 0.85,
            snap: true,
            builder: (context, scroll) => _HomeSheet(
              scroll: scroll,
              draft: draft,
              locating: _locating,
              availability: availability,
              bottomInset: bottomInset,
              onPickup: () => _pick(SearchField.pickup),
              onDropoff: () => _pick(SearchField.dropoff),
              onSavedPlace: (sp) {
                ref.read(bookingDraftProvider.notifier).setDropoff(sp.place);
                _maybeGoToEstimate();
              },
              onFixLocation: () => context.push(Routes.locationPermission),
            ),
          ),
        ],
      ),
      drawer: const _HomeDrawer(),
    );
  }
}

class _HomeSheet extends ConsumerWidget {
  const _HomeSheet({
    required this.scroll,
    required this.draft,
    required this.locating,
    required this.availability,
    required this.bottomInset,
    required this.onPickup,
    required this.onDropoff,
    required this.onSavedPlace,
    required this.onFixLocation,
  });

  final ScrollController scroll;
  final BookingDraft draft;
  final bool locating;
  final LocationAvailability? availability;
  final double bottomInset;
  final VoidCallback onPickup;
  final VoidCallback onDropoff;
  final ValueChanged<SavedPlace> onSavedPlace;
  final VoidCallback onFixLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final saved = ref.watch(savedPlacesProvider);

    return Material(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: Colors.black26,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              Text(l.whereTo, style: AppTypography.headingMd),
              const SizedBox(height: AppSpacing.md),
              _PlaceRow(
                icon: Icons.trip_origin_rounded,
                iconColor: AppColors.pickupMarker,
                label: l.pickupLabel,
                value: locating
                    ? l.locatingYou
                    : draft.pickup?.name ??
                          (availability == LocationAvailability.ready
                              ? l.currentLocation
                              : l.pickupNotSet),
                onTap: onPickup,
                isPlaceholder: draft.pickup == null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _PlaceRow(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.dropoffMarker,
                label: l.dropoffLabel,
                value: draft.dropoff?.name ?? l.homeSearchHint,
                onTap: onDropoff,
                isPlaceholder: draft.dropoff == null,
                emphasized: true,
              ),
              if (availability != null &&
                  availability != LocationAvailability.ready) ...[
                const SizedBox(height: AppSpacing.md),
                StatusBanner(
                  message: availability == LocationAvailability.serviceDisabled
                      ? l.gpsOffTitle
                      : l.locPermTitle,
                  tone: BannerTone.warning,
                  icon: Icons.location_off_rounded,
                  actionLabel: l.locationPausedAction,
                  onAction: onFixLocation,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(l.savedPlaces, style: AppTypography.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              saved.when(
                loading: () => const Column(
                  children: [SkeletonListTile(), SkeletonListTile()],
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (places) => Column(
                  children: [
                    for (final sp in places)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.neutral100,
                          child: Icon(switch (sp.kind) {
                            SavedPlaceKind.home => Icons.home_rounded,
                            SavedPlaceKind.work => Icons.work_rounded,
                            SavedPlaceKind.other => Icons.star_rounded,
                          }, color: AppColors.neutral700),
                        ),
                        title: Text(sp.label),
                        subtitle: Text(
                          sp.place.address.isEmpty
                              ? sp.place.name
                              : sp.place.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSavedPlace(sp),
                      ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.amber50,
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.amber700,
                        ),
                      ),
                      title: Text(l.addPlace),
                      onTap: () => context.push(Routes.places),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isPlaceholder,
    this.emphasized = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isPlaceholder;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Material(
          color: emphasized ? AppColors.amber50 : AppColors.neutral50,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.inputHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: AppTypography.caption),
                          Text(
                            value,
                            style: AppTypography.body.copyWith(
                              color: isPlaceholder
                                  ? AppColors.neutral500
                                  : AppColors.textPrimary,
                              fontWeight: emphasized && !isPlaceholder
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.neutral400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDrawer extends ConsumerWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = switch (ref.watch(authControllerProvider)) {
      Authenticated(:final user) => user,
      _ => null,
    };
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.profile);
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    UserAvatar(user: user, radius: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? l.profile,
                            style: AppTypography.headingSm,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user != null)
                            Text(
                              user.phone,
                              style: AppTypography.bodySecondary,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(l.rideHistory),
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.history);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_rounded),
              title: Text(l.savedPlaces),
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.places);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_emergency_rounded),
              title: Text(l.emergencyContacts),
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.emergencyContacts);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(l.profile),
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.profile);
              },
            ),
          ],
        ),
      ),
    );
  }
}
