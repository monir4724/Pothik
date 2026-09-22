import '../../../core/location/location_service.dart';
import '../../../core/maps/google_places_client.dart';
import '../../../core/maps/osm_places_client.dart';
import '../../rides/domain/ride_models.dart';
import '../domain/saved_place.dart';
import 'places_repository.dart';

/// Live search for any place in Bangladesh.
///
/// Google Places (when billing + APIs are on) and OpenStreetMap geocoders
/// run in parallel so a billed-off Maps key never blocks search. Saved-places
/// CRUD stays on [local].
final class GoogleBackedPlacesRepository implements PlacesRepository {
  GoogleBackedPlacesRepository({
    required this.local,
    required this.google,
    OsmPlacesClient? osm,
  }) : osm = osm ?? OsmPlacesClient();

  final PlacesRepository local;
  final GooglePlacesClient google;
  final OsmPlacesClient osm;

  @override
  Future<List<Place>> search(String query, {GeoPoint? near}) async {
    final q = query.trim();
    if (q.toLowerCase().contains('nodriver')) {
      return local.search(q, near: near);
    }

    // Parallel: don't wait on a failing Google Places key before OSM.
    final parts = await Future.wait([
      _try(
        () => google
            .search(q, near: near)
            .timeout(const Duration(seconds: 3), onTimeout: () => const []),
      ),
      _try(() => osm.search(q, near: near)),
    ]);
    final merged = _merge(parts[0], parts[1]);
    if (merged.isNotEmpty) return merged;

    return local.search(q, near: near);
  }

  @override
  Future<Place?> reverseGeocode(GeoPoint point) async {
    final parts = await Future.wait([
      _try(() async {
        final r = await google
            .reverseGeocode(point)
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
        return r == null ? const <Place>[] : [r];
      }),
      _try(() async {
        final r = await osm.reverseGeocode(point);
        return r == null ? const <Place>[] : [r];
      }),
    ]);
    if (parts[0].isNotEmpty) return parts[0].first;
    if (parts[1].isNotEmpty) return parts[1].first;
    return local.reverseGeocode(point);
  }

  @override
  Future<List<SavedPlace>> saved() => local.saved();

  @override
  Future<SavedPlace> save({
    required SavedPlaceKind kind,
    required String label,
    required Place place,
  }) => local.save(kind: kind, label: label, place: place);

  @override
  Future<void> delete(String id) => local.delete(id);

  Future<List<Place>> _try(Future<List<Place>> Function() fn) async {
    try {
      return await fn();
    } on Object {
      return const [];
    }
  }

  List<Place> _merge(List<Place> a, List<Place> b) {
    final out = <Place>[];
    final seen = <String>{};
    for (final p in [...a, ...b]) {
      final key =
          '${p.name.toLowerCase()}|${p.lat.toStringAsFixed(4)}|${p.lng.toStringAsFixed(4)}';
      if (!seen.add(key)) continue;
      out.add(p);
    }
    return out;
  }
}
