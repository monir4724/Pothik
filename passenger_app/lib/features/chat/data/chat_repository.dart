import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';

abstract interface class ChatRepository {
  Future<List<ChatMessage>> messages(String tripId);

  /// Server rejects with CHAT_CLOSED once the trip is completed/cancelled.
  Future<ChatMessage> send(
    String tripId, {
    required String text,
    required String clientId,
  });
}

final class RemoteChatRepository implements ChatRepository {
  RemoteChatRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ChatMessage>> messages(String tripId) => guardApi(() async {
    final r = await _api.dio.get<Object?>('/trips/$tripId/messages');
    final body = r.data as Map<String, Object?>;
    return (body['data'] as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, Object?>))
        .toList();
  });

  @override
  Future<ChatMessage> send(
    String tripId, {
    required String text,
    required String clientId,
  }) => guardApi(() async {
    final r = await _api.dio.post<Object?>(
      '/trips/$tripId/messages',
      data: {'text': text, 'client_id': clientId},
      options: Options(headers: {kIdempotencyKeyHeader: clientId}),
    );
    final body = r.data as Map<String, Object?>;
    return ChatMessage.fromJson((body['data'] ?? body) as Map<String, Object?>);
  });
}
