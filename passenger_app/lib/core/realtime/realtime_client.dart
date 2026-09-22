import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../network/retry_policy.dart';

enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

/// A Laravel Reverb event on a channel.
final class RealtimeEvent {
  const RealtimeEvent({
    required this.channel,
    required this.event,
    required this.data,
  });

  final String channel;
  final String event;
  final Map<String, Object?> data;
}

/// Minimal Pusher-protocol (v7) client for Laravel Reverb.
///
/// Why hand-rolled: we need explicit control over reconnect/backoff, a
/// connection-state stream the UI can render ("reconnecting…" banner), and
/// private-channel auth via our own `/broadcasting/auth` endpoint. The
/// protocol surface we use is tiny (connect, subscribe, ping/pong, events).
final class RealtimeClient {
  RealtimeClient({
    required AppConfig config,
    required Future<String> Function(String socketId, String channel) authorize,
    WebSocketChannel Function(Uri uri)? connector,
    BackoffPolicy backoff = const BackoffPolicy(max: Duration(seconds: 20)),
  }) : _uri = config.reverbUri,
       _authorize = authorize, // ignore: prefer_initializing_formals
       _connector = connector ?? WebSocketChannel.connect,
       _backoff = backoff; // ignore: prefer_initializing_formals

  static const _log = AppLogger('realtime');

  final Uri _uri;
  final Future<String> Function(String socketId, String channel) _authorize;
  final WebSocketChannel Function(Uri uri) _connector;
  final BackoffPolicy _backoff;

  final _status = StreamController<RealtimeStatus>.broadcast();
  final _events = StreamController<RealtimeEvent>.broadcast();
  final Set<String> _wanted = {};
  final Set<String> _subscribed = {};

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _sub;
  String? _socketId;
  int _attempt = 0;
  bool _closedByUser = true;
  Timer? _pingTimer;
  Timer? _pongDeadline;
  Timer? _reconnectTimer;
  RealtimeStatus _current = RealtimeStatus.disconnected;

  Stream<RealtimeStatus> get status => _status.stream;
  RealtimeStatus get currentStatus => _current;
  Stream<RealtimeEvent> get events => _events.stream;
  bool get isConnected => _current == RealtimeStatus.connected;

  /// Events for one channel only.
  Stream<RealtimeEvent> channel(String name) =>
      _events.stream.where((e) => e.channel == name);

  void connect() {
    if (_channel != null) return;
    _closedByUser = false;
    _open();
  }

  Future<void> disconnect() async {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    await _teardown();
    _setStatus(RealtimeStatus.disconnected);
  }

  /// Idempotent. Subscribes now if connected, otherwise on (re)connect.
  Future<void> subscribe(String channelName) async {
    _wanted.add(channelName);
    if (isConnected) await _sendSubscribe(channelName);
  }

  void unsubscribe(String channelName) {
    _wanted.remove(channelName);
    if (_subscribed.remove(channelName)) {
      _send({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channelName},
      });
    }
  }

  void _open() {
    _setStatus(
      _attempt == 0 ? RealtimeStatus.connecting : RealtimeStatus.reconnecting,
    );
    try {
      final ch = _connector(_uri);
      _channel = ch;
      _sub = ch.stream.listen(
        _onMessage,
        onError: (Object e, StackTrace st) {
          _log.warn('socket error', {'error': e.toString()});
          _scheduleReconnect();
        },
        onDone: () {
          _log.info('socket closed');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } on Object catch (e) {
      _log.warn('connect failed', {'error': e.toString()});
      _scheduleReconnect();
    }
  }

  Future<void> _onMessage(Object? raw) async {
    if (raw is! String) return;
    final Map<String, Object?> msg;
    try {
      msg = jsonDecode(raw) as Map<String, Object?>;
    } on Object {
      return;
    }
    final event = msg['event'] as String? ?? '';
    final data = _decodeData(msg['data']);
    final channelName = msg['channel'] as String?;

    switch (event) {
      case 'pusher:connection_established':
        _socketId = data['socket_id'] as String?;
        final timeoutSec = (data['activity_timeout'] as num?)?.toInt() ?? 120;
        _attempt = 0;
        _setStatus(RealtimeStatus.connected);
        _startHeartbeat(Duration(seconds: timeoutSec));
        for (final c in _wanted) {
          await _sendSubscribe(c);
        }
      case 'pusher:pong':
        _pongDeadline?.cancel();
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': <String, Object?>{}});
      case 'pusher:error':
        _log.warn('server error', {'data': data.toString()});
      case 'pusher_internal:subscription_succeeded':
        if (channelName != null) _subscribed.add(channelName);
      case 'pusher_internal:subscription_error':
        _log.warn('subscription failed', {'channel': channelName});
      default:
        if (channelName != null) {
          _events.add(
            RealtimeEvent(channel: channelName, event: event, data: data),
          );
        }
    }
  }

  Map<String, Object?> _decodeData(Object? d) {
    if (d is Map<String, Object?>) return d;
    if (d is String && d.isNotEmpty) {
      try {
        final decoded = jsonDecode(d);
        if (decoded is Map<String, Object?>) return decoded;
      } on Object {
        // fallthrough
      }
    }
    return const {};
  }

  Future<void> _sendSubscribe(String channelName) async {
    final payload = <String, Object?>{'channel': channelName};
    if (channelName.startsWith('private-') ||
        channelName.startsWith('presence-')) {
      final sid = _socketId;
      if (sid == null) return;
      try {
        payload['auth'] = await _authorize(sid, channelName);
      } on Object catch (e) {
        _log.warn('channel auth failed', {'channel': channelName, 'e': '$e'});
        return;
      }
    }
    _send({'event': 'pusher:subscribe', 'data': payload});
  }

  void _startHeartbeat(Duration activityTimeout) {
    _pingTimer?.cancel();
    // Ping at 80% of the server's activity timeout; reconnect if no pong.
    final interval = activityTimeout * 0.8;
    _pingTimer = Timer.periodic(interval, (_) {
      _send({'event': 'pusher:ping', 'data': <String, Object?>{}});
      _pongDeadline?.cancel();
      _pongDeadline = Timer(const Duration(seconds: 10), () {
        _log.warn('pong timeout');
        _scheduleReconnect();
      });
    });
  }

  void _send(Map<String, Object?> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } on Object catch (e) {
      _log.warn('send failed', {'error': e.toString()});
    }
  }

  void _scheduleReconnect() {
    if (_closedByUser) return;
    if (_reconnectTimer?.isActive ?? false) return;
    unawaited(_teardown());
    _setStatus(RealtimeStatus.reconnecting);
    final delay = _backoff.delayFor(_attempt);
    _attempt++;
    _log.info('reconnect in ${delay.inMilliseconds}ms (attempt $_attempt)');
    _reconnectTimer = Timer(delay, _open);
  }

  Future<void> _teardown() async {
    _pingTimer?.cancel();
    _pongDeadline?.cancel();
    await _sub?.cancel();
    _sub = null;
    final ch = _channel;
    _channel = null;
    _socketId = null;
    _subscribed.clear();
    if (ch == null) return;
    // Never block teardown on the close handshake: a half-dead socket may
    // never ack it. Fire-and-forget with a bounded wait, swallow errors.
    unawaited(
      ch.sink
          .close()
          .timeout(const Duration(seconds: 2))
          .catchError((Object _) {}),
    );
  }

  void _setStatus(RealtimeStatus s) {
    if (_current == s) return;
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  Future<void> dispose() async {
    await disconnect();
    await _status.close();
    await _events.close();
  }
}
