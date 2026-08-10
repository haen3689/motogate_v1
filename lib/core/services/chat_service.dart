import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final String sender; // "user" or "agent"
  final String body;
  final DateTime createdAt;

  bool get fromUser => sender == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int,
        sender: json['sender'] as String? ?? 'agent',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class ChatService {
  static final _dio = ApiClient.instance;

  static Future<List<ChatMessage>> getMessages() async {
    try {
      final res = await _dio.get('/chat_messages');
      final list = res.data['data'] as List<dynamic>;
      return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<ChatMessage?> send(String body) async {
    try {
      final res = await _dio.post('/chat_messages', data: {'body': body});
      return ChatMessage.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static String _cableUrl() {
    final origin = ApiClient.webBaseUrl;
    final wsOrigin = origin.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    return '$wsOrigin/cable';
  }

  /// Opens an ActionCable connection subscribed to this user's chat stream.
  /// Returns a controller for incoming [ChatMessage]s and a function to close
  /// the connection. Best-effort — the caller should keep working with REST
  /// polling/refresh if the socket never connects.
  static ChatSubscription subscribe(int userId) {
    final channel = WebSocketChannel.connect(Uri.parse(_cableUrl()));
    final controller = StreamController<ChatMessage>.broadcast();

    channel.stream.listen(
      (event) {
        try {
          final data = jsonDecode(event as String) as Map<String, dynamic>;
          if (data['type'] == 'ping' || data['type'] == 'welcome') return;
          if (data['type'] == 'confirm_subscription') return;
          final message = data['message'];
          if (message is Map<String, dynamic>) {
            final msgJson = message['message'] is Map<String, dynamic> ? message['message'] : message;
            controller.add(ChatMessage.fromJson(msgJson as Map<String, dynamic>));
          }
        } catch (_) {
          // ignore malformed frames
        }
      },
      onError: (_) => controller.close(),
      onDone: () => controller.close(),
      cancelOnError: true,
    );

    channel.sink.add(jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ChatMessagesChannel', 'user_id': userId}),
    }));

    return ChatSubscription._(channel, controller);
  }
}

class ChatSubscription {
  ChatSubscription._(this._channel, this._controller);

  final WebSocketChannel _channel;
  final StreamController<ChatMessage> _controller;

  Stream<ChatMessage> get messages => _controller.stream;

  void close() {
    _controller.close();
    _channel.sink.close();
  }
}
