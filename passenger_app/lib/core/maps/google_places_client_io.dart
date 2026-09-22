import 'package:dio/dio.dart';

import '../../features/rides/domain/ride_models.dart';
import '../location/location_service.dart';
import 'google_places_client.dart';

GooglePlacesClient createGooglePlacesClient(String apiKey) =>
    IoGooglePlacesClient(apiKey);

/// Android / iOS: Places Autocomplete, then Geocoding as fallback.
/// Restricted to Bangladesh (`country:bd`).
final class IoGooglePlacesClient implements GooglePlacesClient {
  IoGooglePlacesClient(this._apiKey) : _dio = Dio();

  final String _apiKey;
  final Dio _dio;

  @override
  Future<List<Place>> search(String query, {GeoPoint? near}) async {
    final q = query.trim();
    if (q.isEmpty || _apiKey.isEmpty) return const [];

    final fromPlaces = await _autocomplete(q, near: near);
    if (fromPlaces.isNotEmpty) return fromPlaces;
    return _geocode(q);
  }

  @override
  Future<Place?> reverseGeocode(GeoPoint point) async {
    if (_apiKey.isEmpty) return null;
    final r = await _dio.get<Map<String, Object?>>(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: {
        'latlng': '${point.lat},${point.lng}',
        'result_type': 'street_address|route|neighborhood|locality',
        'language': 'bn',
        'region': 'bd',
        'key': _apiKey,
      },
    );
    final results = r.data?['results'] as List? ?? const [];
    if (results.isEmpty) return null;
    return _placeFromGeocode(Map<String, dynamic>.from(results.first as Map));
  }

  Future<List<Place>> _autocomplete(String query, {GeoPoint? near}) async {
    try {
      final r = await _dio.get<Map<String, Object?>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'components': 'country:bd',
          'language': 'bn',
          'key': _apiKey,
          if (near != null) 'location': '${near.lat},${near.lng}',
          if (near != null) 'radius': '80000',
        },
      );
      final status = r.data?['status'] as String? ?? '';
      if (status != 'OK') return const [];
      final preds = r.data?['predictions'] as List? ?? const [];
      final out = <Place>[];
      for (final p in preds.take(8)) {
        final m = p as Map;
        final id = m['place_id'] as String?;
        if (id == null) continue;
        final place = await _details(id);
        if (place != null) out.add(place);
      }
      return out;
    } on Object {
      return const [];
    }
  }

  Future<Place?> _details(String placeId) async {
    final r = await _dio.get<Map<String, Object?>>(
      'https://maps.googleapis.com/maps/api/place/details/json',
      queryParameters: {
        'place_id': placeId,
        'fields': 'place_id,name,formatted_address,geometry',
        'language': 'bn',
        'key': _apiKey,
      },
    );
    if (r.data?['status'] != 'OK') return null;
    final d = r.data?['result'] as Map?;
    if (d == null) return null;
    final loc = (d['geometry'] as Map?)?['location'] as Map?;
    if (loc == null) return null;
    return Place(
      id: d['place_id'] as String? ?? placeId,
      name: (d['name'] as String?)?.trim().isNotEmpty == true
          ? d['name'] as String
          : (d['formatted_address'] as String? ?? ''),
      address: d['formatted_address'] as String? ?? '',
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
    );
  }

  Future<List<Place>> _geocode(String query) async {
    try {
      final r = await _dio.get<Map<String, Object?>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'address': query,
          'components': 'country:BD',
          'region': 'bd',
          'language': 'bn',
          'key': _apiKey,
        },
      );
      if (r.data?['status'] != 'OK') return const [];
      final results = r.data?['results'] as List? ?? const [];
      return [
        for (final row in results)
          if (row is Map)
            _placeFromGeocode(Map<String, dynamic>.from(row)),
      ];
    } on Object {
      return const [];
    }
  }

  Place _placeFromGeocode(Map<String, dynamic> row) {
    final loc =
        (row['geometry'] as Map<String, dynamic>?)?['location']
            as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final formatted = row['formatted_address'] as String? ?? '';
    final comps = row['address_components'] as List? ?? const [];
    var name = formatted.split(',').first.trim();
    for (final c in comps) {
      if (c is! Map) continue;
      final types = (c['types'] as List?)?.cast<String>() ?? const [];
      if (types.contains('point_of_interest') ||
          types.contains('establishment') ||
          types.contains('premise') ||
          types.contains('route') ||
          types.contains('sublocality') ||
          types.contains('locality')) {
        name = c['long_name'] as String? ?? name;
        break;
      }
    }
    return Place(
      id: row['place_id'] as String?,
      name: name,
      address: formatted,
      lat: (loc['lat'] as num?)?.toDouble() ?? 0,
      lng: (loc['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}
