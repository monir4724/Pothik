import 'package:equatable/equatable.dart';

enum ChatSender { passenger, driver }

enum ChatDeliveryStatus { sending, sent, failed }

final class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.sender,
    required this.text,
    required this.sentAt,
    this.status = ChatDeliveryStatus.sent,
    this.clientId,
  });

  factory ChatMessage.fromJson(Map<String, Object?> j) => ChatMessage(
    id: j['id'].toString(),
    tripId: j['trip_id'].toString(),
    sender: (j['sender'] as String) == 'driver'
        ? ChatSender.driver
        : ChatSender.passenger,
    text: j['text'] as String,
    sentAt: DateTime.parse(j['sent_at'] as String),
    clientId: j['client_id'] as String?,
  );

  final String id;
  final String tripId;
  final ChatSender sender;
  final String text;
  final DateTime sentAt;
  final ChatDeliveryStatus status;

  /// Client-generated id used to reconcile optimistic sends with the echo.
  final String? clientId;

  ChatMessage copyWith({String? id, ChatDeliveryStatus? status}) => ChatMessage(
    id: id ?? this.id,
    tripId: tripId,
    sender: sender,
    text: text,
    sentAt: sentAt,
    status: status ?? this.status,
    clientId: clientId,
  );

  @override
  List<Object?> get props => [id, clientId, status, text];
}
