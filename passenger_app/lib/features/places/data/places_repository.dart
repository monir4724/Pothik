import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../../rides/domain/ride_models.dart';
import '../domain/saved_place.dart';

abstract interface class PlacesRepository {
  /// GET /places/search — proxied server-side so the Maps key never ships
  /// with Places scope and results can be cached/rate-limited.
  Future<List<Place>> search(String query, {GeoPoint? near});

  Future<Place?> reverseGeocode(GeoPoint point);

  Future<List<SavedPlace>> saved();
  Future<SavedPlace> save({
    required SavedPlaceKind kind,
    required String label,
    required Place place,
  });
  Future<void> delete(String id);
}

final class RemotePlacesRepository implements PlacesRepository {
  RemotePlacesRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Place>> search(String query, {GeoPoint? near}) =>
      guardApi(() async {
        final r = await _api.dio.get<Object?>(
          '/places/search',
          queryParameters: {
            'q': query,
            if (near != null) 'lat': near.lat,
            if (near != null) 'lng': near.lng,
          },
        );
        final body = r.data as Map<String, Object?>;
        return (body['data'] as List)
            .map((e) => Place.fromJson(e as Map<String, Object?>))
            .toList();
      });

  @override
  Future<Place?> reverseGeocode(GeoPoint point) => guardApi(() async {
    final r = await _api.dio.get<Object?>(
      '/places/reverse',
      queryParameters: {'lat': point.lat, 'lng': point.lng},
    );
    final body = r.data as Map<String, Object?>;
    final d = body['data'];
    return d == null ? null : Place.fromJson(d as Map<String, Object?>);
  });

  @override
  Future<List<SavedPlace>> saved() => guardApi(() async {
    final r = await _api.dio.get<Object?>('/me/places');
    final body = r.data as Map<String, Object?>;
    return (body['data'] as List)
        .map((e) => SavedPlace.fromJson(e as Map<String, Object?>))
        .toList();
  });

  @override
  Future<SavedPlace> save({
    required SavedPlaceKind kind,
    required String label,
    required Place place,
  }) => guardApi(() async {
    final r = await _api.dio.post<Object?>(
      '/me/places',
      data: {'kind': kind.wire, 'label': label, 'place': place.toJson()},
    );
    final body = r.data as Map<String, Object?>;
    return SavedPlace.fromJson((body['data'] ?? body) as Map<String, Object?>);
  });

  @override
  Future<void> delete(String id) =>
      guardApi(() => _api.dio.delete<Object?>('/me/places/$id'));
}
