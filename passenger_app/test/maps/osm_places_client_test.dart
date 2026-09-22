import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/core/maps/osm_places_client.dart';

void main() {
  test('Open-Meteo / Photon find places across Bangladesh', () async {
    final client = OsmPlacesClient();
    final hits = await client.search('Cox\'s Bazar');
    expect(hits, isNotEmpty);
    expect(hits.every((p) => isInBangladesh(p.lat, p.lng)), isTrue);

    final sylhet = await client.search('Sylhet');
    expect(sylhet, isNotEmpty);

    final ctg = await client.search('Chittagong');
    expect(ctg, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
