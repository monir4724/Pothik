import '../../features/rides/domain/ride_models.dart';
import '../location/location_service.dart';

import 'google_places_client_stub.dart'
    if (dart.library.io) 'google_places_client_io.dart'
    if (dart.library.js_interop) 'google_places_client_web.dart'
    as impl;

/// Bangladesh-only Google place search (Autocomplete + Geocode).
abstract interface class GooglePlacesClient {
  Future<List<Place>> search(String query, {GeoPoint? near});
  Future<Place?> reverseGeocode(GeoPoint point);
}

GooglePlacesClient createGooglePlacesClient(String apiKey) =>
    impl.createGooglePlacesClient(apiKey);
