import 'package:dio/dio.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../domain/ride_models.dart';

abstract interface class RideRepository {
  /// POST /rides/estimate — rate-limited server-side.
  Future<FareQuote> estimate({required Place pickup, required Place dropoff});

  /// POST /rides — idempotent via [idempotencyKey]. Fare comes from the
  /// quote on the server; the client sends **no** fare/distance/duration.
  Future<Ride> book({
    required String quoteId,
    required VehicleType vehicleType,
    required String idempotencyKey,
    String? note,
  });

  /// GET /rides/active — `null` when the passenger has no live ride.
  Future<Ride?> activeRide();

  Future<Ride> getRide(String id);

  Future<Ride> cancel(String id, CancelReason reason);

  /// POST /rides/{id}/confirm-cash — idempotent.
  Future<Ride> confirmCash(String id, {required String idempotencyKey});

  Future<void> rate(String id, {required int stars, String? comment});

  /// POST /trips/{id}/location — server validates the passenger is attached
  /// to this *active* trip before accepting.
  Future<void> publishLocation(String id, GeoPoint point);

  Future<ShareLink> createShareLink(String id);
  Future<void> revokeShareLink(String id);

  Future<Page<RideSummary>> history({String? cursor, int limit = 20});

  /// POST /broadcasting/auth — returns the `auth` signature for a private
  /// Reverb channel.
  Future<String> authorizeChannel(String socketId, String channel);
}

final class RemoteRideRepository implements RideRepository {
  RemoteRideRepository(this._api);

  final ApiClient _api;

  Map<String, Object?> _data(Response<Object?> r) {
    final body = r.data as Map<String, Object?>;
    return (body['data'] ?? body) as Map<String, Object?>;
  }

  @override
  Future<FareQuote> estimate({required Place pickup, required Place dropoff}) =>
      guardApi(() async {
        final r = await _api.dio.post<Object?>(
          '/rides/estimate',
          data: {'pickup': pickup.toJson(), 'dropoff': dropoff.toJson()},
        );
        return FareQuote.fromJson(_data(r));
      });

  @override
  Future<Ride> book({
    required String quoteId,
    required VehicleType vehicleType,
    required String idempotencyKey,
    String? note,
  }) => guardApi(() async {
    final r = await _api.dio.post<Object?>(
      '/rides',
      data: {
        'quote_id': quoteId,
        'vehicle_type': vehicleType.wire,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      options: Options(
        headers: {kIdempotencyKeyHeader: idempotencyKey},
        // Booking is the critical path; give it a slightly longer
        // budget than default but still fail fast enough to retry.
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    return Ride.fromJson(_data(r));
  });

  @override
  Future<Ride?> activeRide() => guardApi(() async {
    final r = await _api.dio.get<Object?>('/rides/active');
    final body = r.data as Map<String, Object?>;
    final d = body['data'];
    if (d == null) return null;
    return Ride.fromJson(d as Map<String, Object?>);
  });

  @override
  Future<Ride> getRide(String id) => guardApi(() async {
    final r = await _api.dio.get<Object?>('/rides/$id');
    return Ride.fromJson(_data(r));
  });

  @override
  Future<Ride> cancel(String id, CancelReason reason) => guardApi(() async {
    final r = await _api.dio.post<Object?>(
      '/rides/$id/cancel',
      data: {'reason': reason.wire},
    );
    return Ride.fromJson(_data(r));
  });

  @override
  Future<Ride> confirmCash(String id, {required String idempotencyKey}) =>
      guardApi(() async {
        final r = await _api.dio.post<Object?>(
          '/rides/$id/confirm-cash',
          options: Options(headers: {kIdempotencyKeyHeader: idempotencyKey}),
        );
        return Ride.fromJson(_data(r));
      });

  @override
  Future<void> rate(String id, {required int stars, String? comment}) =>
      guardApi(
        () => _api.dio.post<Object?>(
          '/rides/$id/rating',
          data: {'stars': stars, 'comment': comment},
        ),
      );

  @override
  Future<void> publishLocation(String id, GeoPoint point) => guardApi(
    () => _api.dio.post<Object?>(
      '/trips/$id/location',
      data: {
        'lat': point.lat,
        'lng': point.lng,
        'accuracy_m': point.accuracyMeters,
        'at': (point.at ?? DateTime.now()).toUtc().toIso8601String(),
      },
      options: Options(receiveTimeout: const Duration(seconds: 6)),
    ),
  );

  @override
  Future<ShareLink> createShareLink(String id) => guardApi(() async {
    final r = await _api.dio.post<Object?>('/rides/$id/share-link');
    return ShareLink.fromJson(_data(r));
  });

  @override
  Future<void> revokeShareLink(String id) =>
      guardApi(() => _api.dio.delete<Object?>('/rides/$id/share-link'));

  @override
  Future<Page<RideSummary>> history({String? cursor, int limit = 20}) =>
      guardApi(() async {
        final r = await _api.dio.get<Object?>(
          '/rides',
          queryParameters: {'limit': limit, 'cursor': ?cursor},
        );
        final body = r.data as Map<String, Object?>;
        final items = (body['data'] as List)
            .map((e) => RideSummary.fromJson(e as Map<String, Object?>))
            .toList();
        final meta = body['meta'] as Map<String, Object?>?;
        return Page(items: items, nextCursor: meta?['next_cursor'] as String?);
      });

  @override
  Future<String> authorizeChannel(String socketId, String channel) =>
      guardApi(() async {
        final r = await _api.dio.post<Object?>(
          '/broadcasting/auth',
          data: {'socket_id': socketId, 'channel_name': channel},
        );
        final body = r.data as Map<String, Object?>;
        return body['auth'] as String;
      });
}
