import 'package:connectivity_plus/connectivity_plus.dart';

/// Coarse network state for the offline banner and for deciding whether to
/// even attempt a booking call. Interface-level only — "connected" here does
/// not guarantee the API is reachable; callers still handle errors.
enum NetworkStatus { online, offline }

Stream<NetworkStatus> watchNetworkStatus([Connectivity? connectivity]) {
  final c = connectivity ?? Connectivity();
  return c.onConnectivityChanged.map(_map).distinct();
}

Future<NetworkStatus> currentNetworkStatus([Connectivity? connectivity]) async {
  final c = connectivity ?? Connectivity();
  return _map(await c.checkConnectivity());
}

NetworkStatus _map(List<ConnectivityResult> results) {
  final online = results.any(
    (r) => r != ConnectivityResult.none && r != ConnectivityResult.bluetooth,
  );
  return online ? NetworkStatus.online : NetworkStatus.offline;
}
