import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  static const String _defaultWebSocketUrl = 'wss://lashaunda-hereditary-nonconvectively.ngrok-free.dev/ws';

  // StreamController lets us easily listen to incoming messages from the WebSocket 
  // and broadcast them to multiple devices/listeners if needed.
  final StreamController<Map<String, dynamic>> _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;
  
  // Connect to the WebSocket server. This is called when the app starts or when we want to establish a connection.
  Future<bool> connect() async {
    if (_channel != null && _channel!.closeCode == null) return true; // if already connected, do nothing

    final url = const String.fromEnvironment('WEBSOCKET_URL', defaultValue: _defaultWebSocketUrl);

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'}, // This header is needed to bypass ngrok's browser warning for WebSocket connections.
        );
      // waiting until the connection is fully established before proceeding. 
      // This ensures that we don't try to send or receive messages before the WebSocket is ready.
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

  // Helper method to send data to the WebSocket server. It checks if the connection is established before trying to send a message.
  void _sendData(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      print("WebSocket is not connected. Cannot send data.");
    }
  }
  
  // This method is used to send a move (in FEN format) to the server. 
  // It constructs a message with the type "move" and the FEN string, 
  // and sends it using the _sendData helper method.
  void sendMove(String fen) => _sendData({"type": "move", "fen": fen});

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

  // public game
  void joinPublic() => _sendData({"action": "join_public"});
  
  // creating private room (friend code)
  void createPrivate(String roomId) => _sendData({"action": "create_private", "room_id": roomId});

  // joining the private room (friend code)
  void joinPrivate(String roomId) => _sendData({"action": "join_private", "room_id": roomId});

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
