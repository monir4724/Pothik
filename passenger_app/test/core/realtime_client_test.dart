import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/core/network/retry_policy.dart';
import 'package:pothik_passenger/core/realtime/realtime_client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../helpers/test_config.dart';

/// In-memory WebSocketChannel: [incoming] feeds the client, [sent] captures
/// what the client writes.
final class FakeSocket {
  FakeSocket() {
    final toClient = StreamController<Object?>();
    final fromClient = StreamController<Object?>();
    incoming = toClient;
    sent = fromClient.stream.map(
      (m) => jsonDecode(m! as String) as Map<String, Object?>,
    );
    channel = _FakeWsChannel(
      StreamChannel<Object?>(toClient.stream, fromClient.sink),
    );
  }

  late final StreamController<Object?> incoming;
  late final Stream<Map<String, Object?>> sent;
  late final WebSocketChannel channel;

  void push(Map<String, Object?> msg) => incoming.add(jsonEncode(msg));
}

final class _FakeWsChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  _FakeWsChannel(this._inner);

  final StreamChannel<Object?> _inner;

  @override
  Stream<Object?> get stream => _inner.stream;

  @override
  WebSocketSink get sink => _FakeSink(_inner.sink);

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();
}

final class _FakeSink implements WebSocketSink {
  _FakeSink(this._inner);

  final StreamSink<Object?> _inner;

  @override
  void add(Object? data) => _inner.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<Object?> stream) => _inner.addStream(stream);

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    // A StreamController's close() future only completes once a listener
    // drains it; tests without a `sent` listener would otherwise hang.
    unawaited(_inner.close());
    return Future.value();
  }

  @override
  Future<void> get done => _inner.done;
}

void main() {
  late FakeSocket socket;
  late RealtimeClient client;
  var connectCount = 0;

  setUp(() {
    connectCount = 0;
    socket = FakeSocket();
    client = RealtimeClient(
      config: testConfig,
      authorize: (sid, ch) async => 'auth:$sid:$ch',
      connector: (_) {
        connectCount++;
        return socket.channel;
      },
      backoff: const BackoffPolicy(
        initial: Duration(milliseconds: 1),
        max: Duration(milliseconds: 1),
      ),
    );
  });

  tearDown(() => client.dispose());

  test(
    'connects, subscribes to private channel with auth, emits events',
    () async {
      final sentMsgs = <Map<String, Object?>>[];
      socket.sent.listen(sentMsgs.add);
      final statuses = <RealtimeStatus>[];
      client.status.listen(statuses.add);

      client.connect();
      await client.subscribe('private-trip.42');

      socket.push({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': '1.1', 'activity_timeout': 120}),
      });
      await Future<void>.delayed(Duration.zero);

      expect(client.isConnected, isTrue);
      expect(statuses, contains(RealtimeStatus.connected));
      expect(
        sentMsgs.any(
          (m) =>
              m['event'] == 'pusher:subscribe' &&
              (m['data'] as Map)['channel'] == 'private-trip.42' &&
              (m['data'] as Map)['auth'] == 'auth:1.1:private-trip.42',
        ),
        isTrue,
      );

      final events = <RealtimeEvent>[];
      client.channel('private-trip.42').listen(events.add);
      socket.push({
        'event': 'TripAccepted',
        'channel': 'private-trip.42',
        'data': jsonEncode({
          'ride': {'id': '42'},
        }),
      });
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.event, 'TripAccepted');
      expect((events.first.data['ride'] as Map)['id'], '42');
    },
  );

  test('replies to server ping with pong', () async {
    final sentMsgs = <Map<String, Object?>>[];
    socket.sent.listen(sentMsgs.add);
    client.connect();
    socket.push({'event': 'pusher:ping', 'data': '{}'});
    await Future<void>.delayed(Duration.zero);
    expect(sentMsgs.any((m) => m['event'] == 'pusher:pong'), isTrue);
  });

  test('reconnects with backoff when socket closes', () async {
    client.connect();
    expect(connectCount, 1);
    final statuses = <RealtimeStatus>[];
    client.status.listen(statuses.add);

    // Swap in a fresh socket for the reconnect, then close the first one.
    final first = socket;
    socket = FakeSocket();
    await first.incoming.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(connectCount, 2);
    expect(statuses, contains(RealtimeStatus.reconnecting));
  });

  test('disconnect() stops reconnect attempts', () async {
    client.connect();
    await client.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(connectCount, 1);
    expect(client.currentStatus, RealtimeStatus.disconnected);
  });
}
