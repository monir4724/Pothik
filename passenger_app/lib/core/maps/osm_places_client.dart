import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/rides/domain/ride_models.dart';
import '../location/location_service.dart';

/// Bangladesh bounding box used to drop out-of-country hits.
bool isInBangladesh(double lat, double lng) =>
    lat >= 20.3 && lat <= 26.85 && lng >= 87.85 && lng <= 92.8;

/// OpenStreetMap / free geocoders so place search works when Google Places
/// billing is off. Results stay in Bangladesh and are shown on Google Maps.
final class OsmPlacesClient {
  OsmPlacesClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'PothikPassenger/1.0 (https://pothik.app)',
              },
            ),
          );

  final Dio _dio;

  static const _bdBbox = '88.01,20.59,92.68,26.64';

  Future<List<Place>> search(String query, {GeoPoint? near}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final variants = <String>{
      q,
      if (!_mentionsBd(q)) '$q Bangladesh',
      if (!_mentionsBd(q)) '$q, Bangladesh',
    }.toList();

    final futures = <Future<List<Place>>>[
      for (final v in variants) _photon(v, near: near),
      for (final v in variants) _openMeteo(v),
      // Nominatim often blocks browser CORS; still useful on Android/iOS.
      if (!kIsWeb) for (final v in variants) _nominatim(v),
    ];

    final chunks = await Future.wait(futures);
    return _dedupe([for (final c in chunks) ...c]);
  }

  Future<Place?> reverseGeocode(GeoPoint point) async {
    try {
      final r = await _dio.get<Map<String, Object?>>(
        'https://photon.komoot.io/reverse',
        queryParameters: {
          'lat': point.lat,
          'lon': point.lng,
          'lang': 'en',
        },
      );
      final features = r.data?['features'] as List? ?? const [];
      if (features.isEmpty) return null;
      return _fromPhoton(features.first);
    } on Object {
      return null;
    }
  }

  bool _mentionsBd(String q) {
    final t = q.toLowerCase();
    return t.contains('bangladesh') ||
        t.contains('বাংলাদেশ') ||
        t.contains(', bd') ||
        t.endsWith(' bd');
  }

  Future<List<Place>> _photon(String query, {GeoPoint? near}) async {
    try {
      final r = await _dio.get<Map<String, Object?>>(
        'https://photon.komoot.io/api/',
        queryParameters: {
          'q': query,
          'limit': 15,
          'lang': 'en',
          'bbox': _bdBbox,
          if (near != null) 'lat': near.lat,
          if (near != null) 'lon': near.lng,
        },
      );
      final features = r.data?['features'] as List? ?? const [];
      return [
        for (final f in features)
          if (_fromPhoton(f) case final p?) p,
      ];
    } on Object {
      return const [];
    }
  }

  Future<List<Place>> _openMeteo(String query) async {
    try {
      final langs = RegExp(r'[\u0980-\u09FF]').hasMatch(query)
          ? const ['bn', 'en']
          : const ['en'];
      final out = <Place>[];
      for (final lang in langs) {
        final r = await _dio.get<Map<String, Object?>>(
          'https://geocoding-api.open-meteo.com/v1/search',
          queryParameters: {
            'name': query,
            'count': 15,
            'language': lang,
            'format': 'json',
            'countryCode': 'BD',
          },
        );
        final rows = r.data?['results'] as List? ?? const [];
        for (final row in rows) {
          if (row is! Map) continue;
          final m = Map<String, dynamic>.from(row);
          final code = (m['country_code'] as String?)?.toUpperCase();
          final lat = (m['latitude'] as num?)?.toDouble();
          final lng = (m['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;
          if (code != null && code != 'BD') continue;
          if (!isInBangladesh(lat, lng)) continue;
          final name = (m['name'] as String?)?.trim() ?? '';
          if (name.isEmpty) continue;
          final admin = [
            m['admin2'],
            m['admin1'],
            m['country'],
          ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
          out.add(
            Place(
              id: 'om-${m['id']}',
              name: name,
              address: admin,
              lat: lat,
              lng: lng,
            ),
          );
        }
        if (out.isNotEmpty) break;
      }
      return out;
    } on Object {
      return const [];
    }
  }

  Future<List<Place>> _nominatim(String query) async {
    try {
      final r = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 12,
          'countrycodes': 'bd',
          'addressdetails': 0,
        },
      );
      final rows = r.data ?? const [];
      final out = <Place>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final lat = double.tryParse('${m['lat']}');
        final lng = double.tryParse('${m['lon']}');
        if (lat == null || lng == null || !isInBangladesh(lat, lng)) continue;
        final display = (m['display_name'] as String?)?.trim() ?? '';
        if (display.isEmpty) continue;
        out.add(
          Place(
            id: 'nom-${m['place_id']}',
            name: display.split(',').first.trim(),
            address: display,
            lat: lat,
            lng: lng,
          ),
        );
      }
      return out;
    } on Object {
      return const [];
    }
  }

  Place? _fromPhoton(Object? raw) {
    if (raw is! Map) return null;
    final f = Map<String, dynamic>.from(raw);
    final geom = f['geometry'];
    if (geom is! Map) return null;
    final coords = geom['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    final lng = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    if (!isInBangladesh(lat, lng)) return null;
    final props = f['properties'];
    if (props is! Map) return null;
    final p = Map<String, dynamic>.from(props);
    final cc = (p['countrycode'] as String?)?.toUpperCase();
    if (cc != null && cc.isNotEmpty && cc != 'BD') return null;
    final name =
        (p['name'] as String?)?.trim() ??
        (p['street'] as String?)?.trim() ??
        '';
    if (name.isEmpty) return null;
    final address = [
      p['street'],
      p['district'],
      p['city'] ?? p['locality'],
      p['county'] ?? p['state'],
      p['country'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    return Place(
      id: 'osm-${p['osm_id'] ?? '$lat,$lng'}',
      name: name,
      address: address,
      lat: lat,
      lng: lng,
    );
  }

  List<Place> _dedupe(List<Place> input) {
    final out = <Place>[];
    final seen = <String>{};
    for (final p in input) {
      final key =
          '${p.name.toLowerCase()}|${p.lat.toStringAsFixed(4)}|${p.lng.toStringAsFixed(4)}';
      if (!seen.add(key)) continue;
      out.add(p);
    }
    return out;
  }
}
