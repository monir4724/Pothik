import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../../features/rides/domain/ride_models.dart';
import '../location/location_service.dart';
import 'google_places_client.dart';

GooglePlacesClient createGooglePlacesClient(String apiKey) =>
    WebGooglePlacesClient();

/// Chrome / Flutter web: Places Autocomplete via Maps JS, Geocoder fallback.
/// `componentRestrictions.country = bd` so results stay in Bangladesh.
final class WebGooglePlacesClient implements GooglePlacesClient {
  @override
  Future<List<Place>> search(String query, {GeoPoint? near}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    await _waitForMaps();
    final fromPlaces = await _autocomplete(q, near: near);
    if (fromPlaces.isNotEmpty) return fromPlaces;
    return _geocode(address: q);
  }

  @override
  Future<Place?> reverseGeocode(GeoPoint point) async {
    await _waitForMaps();
    final results = await _geocode(lat: point.lat, lng: point.lng);
    return results.isEmpty ? null : results.first;
  }

  Future<List<Place>> _autocomplete(String query, {GeoPoint? near}) async {
    if (!_hasPlaces()) return const [];
    final service = _construct('google.maps.places.AutocompleteService');
    if (service == null) return const [];

    final req = JSObject();
    req.setProperty('input'.toJS, query.toJS);
    final restrict = JSObject();
    restrict.setProperty('country'.toJS, 'bd'.toJS);
    req.setProperty('componentRestrictions'.toJS, restrict);
    if (near != null) {
      req.setProperty(
        'location'.toJS,
        _latLngLiteral(near.lat, near.lng),
      );
      req.setProperty('radius'.toJS, 80000.toJS);
    }

    final preds = await _callbackList(service, 'getPlacePredictions', req);
    if (preds.isEmpty) return const [];

    final attr = _div();
    final details = _construct('google.maps.places.PlacesService', attr);
    if (details == null) return const [];

    final out = <Place>[];
    for (final p in preds.take(8)) {
      final id = _str(p, 'place_id');
      if (id == null) continue;
      final dReq = JSObject();
      dReq.setProperty('placeId'.toJS, id.toJS);
      dReq.setProperty(
        'fields'.toJS,
        <JSAny>['name'.toJS, 'formatted_address'.toJS, 'geometry'.toJS, 'place_id'.toJS]
            .toJS,
      );
      final got = await _callbackList(details, 'getDetails', dReq, single: true);
      if (got.isEmpty) continue;
      final place = _placeFromJs(got.first);
      if (place != null) out.add(place);
    }
    return out;
  }

  Future<List<Place>> _geocode({String? address, double? lat, double? lng}) async {
    final geocoder = _construct('google.maps.Geocoder');
    if (geocoder == null) return const [];
    final req = JSObject();
    final restrict = JSObject();
    restrict.setProperty('country'.toJS, 'BD'.toJS);
    req.setProperty('componentRestrictions'.toJS, restrict);
    req.setProperty('region'.toJS, 'BD'.toJS);
    if (address != null) req.setProperty('address'.toJS, address.toJS);
    if (lat != null && lng != null) {
      req.setProperty('location'.toJS, _latLngLiteral(lat, lng));
    }
    final results = await _callbackList(geocoder, 'geocode', req);
    return [
      for (final row in results)
        ?_placeFromJs(row),
    ];
  }

  Place? _placeFromJs(JSObject row) {
    final geometry = row.getProperty('geometry'.toJS);
    if (geometry == null || geometry.isUndefinedOrNull) return null;
    final loc = (geometry as JSObject).getProperty('location'.toJS);
    if (loc == null || loc.isUndefinedOrNull) return null;
    final latLng = loc as JSObject;
    final lat = _num(latLng, 'lat');
    final lng = _num(latLng, 'lng');
    if (lat == null || lng == null) return null;
    final formatted = _str(row, 'formatted_address') ?? _str(row, 'description') ?? '';
    final name = _str(row, 'name') ?? formatted.split(',').first.trim();
    return Place(
      id: _str(row, 'place_id'),
      name: name,
      address: formatted,
      lat: lat,
      lng: lng,
    );
  }

  double? _num(JSObject o, String key) {
    final v = o.getProperty(key.toJS);
    if (v == null || v.isUndefinedOrNull) {
      // LatLng from the JS API exposes lat()/lng() methods.
      final fn = o.getProperty(key.toJS);
      if (fn.isA<JSFunction>()) {
        final r = o.callMethod(key.toJS);
        return (r as JSNumber?)?.toDartDouble;
      }
      return null;
    }
    if (v.isA<JSFunction>()) {
      final r = o.callMethod(key.toJS);
      return (r as JSNumber?)?.toDartDouble;
    }
    if (v.isA<JSNumber>()) return (v as JSNumber).toDartDouble;
    return null;
  }

  String? _str(JSObject o, String key) {
    final v = o.getProperty(key.toJS);
    if (v == null || v.isUndefinedOrNull) return null;
    if (v.isA<JSString>()) return (v as JSString).toDart;
    return v.dartify()?.toString();
  }

  JSObject _latLngLiteral(double lat, double lng) {
    final o = JSObject();
    o.setProperty('lat'.toJS, lat.toJS);
    o.setProperty('lng'.toJS, lng.toJS);
    return o;
  }

  JSObject? _construct(String path, [JSAny? arg]) {
    JSAny? cur = globalContext;
    for (final part in path.split('.')) {
      if (cur == null || cur.isUndefinedOrNull) return null;
      cur = (cur as JSObject).getProperty(part.toJS);
    }
    if (cur == null || cur.isUndefinedOrNull || !cur.isA<JSFunction>()) {
      return null;
    }
    if (arg != null) {
      return _jsNew1(cur as JSFunction, arg);
    }
    return _jsNew0(cur as JSFunction);
  }

  JSObject _div() {
    final document = globalContext.getProperty('document'.toJS) as JSObject;
    return document.callMethod('createElement'.toJS, 'div'.toJS) as JSObject;
  }

  bool _hasPlaces() {
    final google = globalContext.getProperty('google'.toJS);
    if (google == null || google.isUndefinedOrNull) return false;
    final maps = (google as JSObject).getProperty('maps'.toJS);
    if (maps == null || maps.isUndefinedOrNull) return false;
    final places = (maps as JSObject).getProperty('places'.toJS);
    return places != null && !places.isUndefinedOrNull;
  }

  Future<void> _waitForMaps() async {
    for (var i = 0; i < 80; i++) {
      final google = globalContext.getProperty('google'.toJS);
      if (google != null && !google.isUndefinedOrNull) {
        final maps = (google as JSObject).getProperty('maps'.toJS);
        if (maps != null && !maps.isUndefinedOrNull) {
          final g = (maps as JSObject).getProperty('Geocoder'.toJS);
          if (g != null && !g.isUndefinedOrNull) return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<List<JSObject>> _callbackList(
    JSObject service,
    String method,
    JSObject request, {
    bool single = false,
  }) {
    final c = Completer<List<JSObject>>();
    late final JSFunction cb;
    cb = ((JSAny? results, JSAny? status) {
      final st = status.dartify()?.toString() ?? '';
      if (st != 'OK' && st != 'ZERO_RESULTS') {
        if (!c.isCompleted) c.complete(const []);
        return;
      }
      if (results == null || results.isUndefinedOrNull) {
        if (!c.isCompleted) c.complete(const []);
        return;
      }
      if (single) {
        if (!c.isCompleted) c.complete([results as JSObject]);
        return;
      }
      final out = <JSObject>[];
      final arr = results as JSObject;
      final len = (arr.getProperty('length'.toJS) as JSNumber?)?.toDartInt ?? 0;
      for (var i = 0; i < len; i++) {
        final item = arr.getProperty(i.toJS);
        if (item != null && !item.isUndefinedOrNull) {
          out.add(item as JSObject);
        }
      }
      if (!c.isCompleted) c.complete(out);
    }).toJS;
    service.callMethod(method.toJS, request, cb);
    return c.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => const [],
    );
  }
}

@JS('Reflect.construct')
external JSObject _reflectConstruct(JSFunction ctor, JSArray args);

JSObject _jsNew0(JSFunction ctor) =>
    _reflectConstruct(ctor, <JSAny>[].toJS);

JSObject _jsNew1(JSFunction ctor, JSAny arg) =>
    _reflectConstruct(ctor, <JSAny>[arg].toJS);
