import '../../features/rides/domain/ride_models.dart';
import '../location/location_service.dart';
import 'google_places_client.dart';

GooglePlacesClient createGooglePlacesClient(String apiKey) =>
    _UnavailablePlacesClient();

final class _UnavailablePlacesClient implements GooglePlacesClient {
  @override
  Future<List<Place>> search(String query, {GeoPoint? near}) async =>
      const [];

  @override
  Future<Place?> reverseGeocode(GeoPoint point) async => null;
}
