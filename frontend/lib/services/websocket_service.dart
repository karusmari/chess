import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  static const String _defaultWebSocketUrl =
      'wss://lashaunda-hereditary-nonconvectively.ngrok-free.dev/ws';

  // StreamController võimaldab meil saata andmeid mitmele ekraanile korraga
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Future<bool> connect() async {
    _channel?.sink.close();
    final url = const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: _defaultWebSocketUrl,
    );

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      // Ootame, kuni stream on valmis (või lihtsalt anname hetke aega)
      await _channel!.ready;
      print("Connected to $url");

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
      print("Connection error: $e");
      return false;
    }
  }

  void _sendData(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      print("WebSocket is not connected. Cannot send data.");
    }
  }

  void sendMove(String fen) {
    if (_channel != null) {
      _sendData({"type": "move", "fen": fen});
    }
  }

  void sendReady() {
    _sendData({"type": "ready"});
  }

  Future<void> cancelWaitingById(String playerId) async {
    if (playerId.isEmpty) return;

    final url = const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: _defaultWebSocketUrl,
    );

    try {
      final tempChannel = WebSocketChannel.connect(Uri.parse(url));
      await tempChannel.ready;
      tempChannel.sink.add(
        jsonEncode({"action": "cancel_waiting", "player_id": playerId}),
      );
      await tempChannel.sink.close();
    } catch (e) {
      print("Cancel waiting request failed: $e");
    }
  }

  Future<void> cancelPrivateRoomById(String roomId) async {
    if (roomId.isEmpty) return;

    final url = const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: _defaultWebSocketUrl,
    );

    try {
      final tempChannel = WebSocketChannel.connect(Uri.parse(url));
      await tempChannel.ready;
      tempChannel.sink.add(
        jsonEncode({"action": "cancel_waiting", "room_id": roomId}),
      );
      await tempChannel.sink.close();
    } catch (e) {
      print("Cancel private room request failed: $e");
    }
  }

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

  // 1. AVALIK MÄNG
  void joinPublic() {
    _sendData({"action": "join_public"});
  }

  // 2. LOO PRIVAATNE (Kutsu sõber)
  void createPrivate(String roomId) {
    _sendData({"action": "create_private", "room_id": roomId});
  }

  // 3. LIITU PRIVAATSEGA (Sõbra koodiga)
  void joinPrivate(String roomId) {
    _sendData({"action": "join_private", "room_id": roomId});
  }
}

// Teeme globaalse teenuse, mida saame igal pool kasutada
final socketService = WebSocketService();
