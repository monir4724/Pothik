import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/connectivity/connectivity_status.dart';
import '../../l10n/generated/app_localizations.dart';

/// Dhaka centre — sane default before we have a GPS fix.
const LatLng kDhakaCenter = LatLng(23.7806, 90.4074);

  /// Thin wrapper so screens don't hold a raw [GoogleMapController].
  /// Do **not** call [GoogleMapController.dispose] here — [GoogleMap] owns
  /// that lifecycle. Double-dispose on web asserts
  /// "Maps cannot be retrieved before calling buildView!".
  class PothikMapController {
    PothikMapController(this._google);

    final GoogleMapController _google;

    Future<void> animateTo(LatLng target, {double zoom = 16}) {
      return _google.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
    }

    Future<void> fitBounds(
      LatLng southwest,
      LatLng northeast, {
      double padding = 80,
    }) {
      return _google.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: southwest, northeast: northeast),
          padding,
        ),
      );
    }

    void dispose() {
      // Intentionally empty — see class doc.
    }
  }

/// GoogleMap with production wrapping:
/// - a neutral placeholder underneath so a slow tile load never flashes
///   a black/blank rectangle;
/// - a "loading slowly" hint after 4s or when offline;
/// - lite mode on request (static bitmap; cheap on low-end devices);
/// - semantic label for screen readers (the map itself is not navigable).
class MapView extends ConsumerStatefulWidget {
  const MapView({
    required this.initialTarget,
    this.initialZoom = 15,
    this.markers = const {},
    this.polylines = const {},
    this.padding = EdgeInsets.zero,
    this.onMapCreated,
    this.onCameraIdle,
    this.onCameraMove,
    this.myLocationEnabled = false,
    this.liteMode = false,
    this.interactive = true,
    super.key,
  });

  final LatLng initialTarget;
  final double initialZoom;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final EdgeInsets padding;
  final ValueChanged<PothikMapController>? onMapCreated;
  final VoidCallback? onCameraIdle;
  final ValueChanged<CameraPosition>? onCameraMove;
  final bool myLocationEnabled;
  final bool liteMode;
  final bool interactive;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  bool _created = false;
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_created) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final offline =
        ref.watch(networkStatusProvider).value == NetworkStatus.offline;

    return Semantics(
      label: l.semanticMap,
      image: true,
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _MapPlaceholder(),
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialTarget,
                zoom: widget.initialZoom,
              ),
              markers: widget.markers,
              polylines: widget.polylines,
              padding: widget.padding,
              liteModeEnabled: widget.liteMode,
              myLocationEnabled: widget.myLocationEnabled,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              buildingsEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              scrollGesturesEnabled: widget.interactive,
              zoomGesturesEnabled: widget.interactive,
              onCameraIdle: widget.onCameraIdle,
              onCameraMove: widget.onCameraMove,
              onMapCreated: (c) {
                _slowTimer?.cancel();
                if (mounted) setState(() => _created = true);
                widget.onMapCreated?.call(PothikMapController(c));
              },
            ),
            if ((_slow && !_created) || offline)
              Positioned(
                top: widget.padding.top + AppSpacing.md,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.neutral900.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadius.pill),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        l.mapSlowHint,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Subtle grid so the region reads as "map" even before tiles arrive.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(), child: const SizedBox.expand());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.neutral100);
    final p = Paint()
      ..color = AppColors.neutral200
      ..strokeWidth = 1;
    const step = 48.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Marker helpers with consistent hues. Custom bitmap assets can replace
/// these later without touching call sites.
abstract final class MapMarkers {
  static Marker pickup(LatLng at, {String? title}) => Marker(
    markerId: const MarkerId('pickup'),
    position: at,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    infoWindow: title == null ? InfoWindow.noText : InfoWindow(title: title),
  );

  static Marker dropoff(LatLng at, {String? title}) => Marker(
    markerId: const MarkerId('dropoff'),
    position: at,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    infoWindow: title == null ? InfoWindow.noText : InfoWindow(title: title),
  );

  static Marker driver(LatLng at, {double? bearing}) => Marker(
    markerId: const MarkerId('driver'),
    position: at,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    rotation: bearing ?? 0,
    flat: true,
    anchor: const Offset(0.5, 0.5),
    zIndexInt: 10,
  );
}
