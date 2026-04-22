import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  static const String _defaultWebSocketUrl = 'wss://lashaunda-hereditary-nonconvectively.ngrok-free.dev/ws';
  static const Map<String, String> _ngrokHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

  // StreamController lets us easily listen to incoming messages from the WebSocket
  // and broadcast them to multiple devices/listeners if needed.
  final StreamController<Map<String, dynamic>> _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  String get _resolvedWebSocketUrl {
    return const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: _defaultWebSocketUrl,
    );
  }

  // Connect to the WebSocket server. This is called when the app starts or when we want to establish a connection.
  Future<bool> connect() async {
    if (_channel != null && _channel!.closeCode == null) return true; // if already connected, do nothing

    final url = _resolvedWebSocketUrl;

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        headers:
            _ngrokHeaders, // This header is needed to bypass ngrok's browser warning for WebSocket connections.
      );
      // waiting until the connection is fully established before proceeding.
      // This ensures that we don't try to send or receive messages before the WebSocket is ready.
      await _channel!.ready;
      debugPrint("Connected to $url");

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          _controller.add(data);
        },
        onError: (error) =>
            _controller.add({"status": "error", "message": error.toString()}),
        onDone: () => _controller.add({"status": "disconnected"}),
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      debugPrint("Connection error: $e");
      return false;
    }
  }

  // Helper method to send data to the WebSocket server. It checks if the connection is established before trying to send a message.
  void _sendData(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      debugPrint("WebSocket is not connected. Cannot send data.");
    }
  }

  // This method is used to send a move (in FEN format) to the server.
  // It constructs a message with the type "move" and the FEN string,
  // and sends it using the _sendData helper method.
  void sendMove(String fen) => _sendData({"type": "move", "fen": fen});

  Future<void> _sendOneShotCancel(Map<String, dynamic> payload) async {
    final url = _resolvedWebSocketUrl;

    try {
      final tempChannel = IOWebSocketChannel.connect(
        Uri.parse(url),
        headers: _ngrokHeaders,
      );
      await tempChannel.ready;
      tempChannel.sink.add(jsonEncode(payload));
      await tempChannel.sink.close();
    } catch (e) {
      debugPrint("Cancel request failed: $e");
    }
  }

  Future<void> cancelWaitingById(String playerId) async {
    if (playerId.isEmpty) return;
    await _sendOneShotCancel({
      "action": "cancel_waiting",
      "player_id": playerId,
    });
  }

  Future<void> cancelPrivateRoomById(String roomId) async {
    if (roomId.isEmpty) return;
    await _sendOneShotCancel({"action": "cancel_waiting", "room_id": roomId});
  }

  // public game
  void joinPublic() => _sendData({"action": "join_public"});

  // creating private room (friend code)
  void createPrivate(String roomId) =>
      _sendData({"action": "create_private", "room_id": roomId});

  // joining the private room (friend code)
  void joinPrivate(String roomId) =>
      _sendData({"action": "join_private", "room_id": roomId});

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}

// creating a global instance of the WebSocketService that can be imported and used across the app.
final socketService = WebSocketService();
