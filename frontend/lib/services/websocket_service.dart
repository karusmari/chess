import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  
  // StreamController võimaldab meil saata andmeid mitmele ekraanile korraga
  final StreamController<Map<String, dynamic>> _controller = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  // websocket_service.dart sees:

Future<void> connect() async {
  _channel?.sink.close();
  final uri = Uri.parse('ws://localhost:8080/ws');
  
  try {
    _channel = WebSocketChannel.connect(uri);
    // Ootame, kuni stream on valmis (või lihtsalt anname hetke aega)
    await _channel!.ready; 
    print("Connected to $uri");

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        _controller.add(data);
      },
      onError: (error) => _controller.add({"status": "error", "message": error.toString()}),
      onDone: () => _controller.add({"status": "disconnected"}),
      cancelOnError: true,
    );
  } catch (e) {
    print("Connection error: $e");
  }
}

  void sendMove(String fen) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({"type": "move", "fen": fen}));
    }
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }

  // 1. AVALIK MÄNG
  void joinPublic() {
    _channel?.sink.add(jsonEncode({
      "action": "join_public"
    }));
  }

  // 2. LOO PRIVAATNE (Kutsu sõber)
  void createPrivate(String roomId) {
    _channel?.sink.add(jsonEncode({
      "action": "create_private",
      "room_id": roomId
    }));
  }

  // 3. LIITU PRIVAATSEGA (Sõbra koodiga)
  void joinPrivate(String roomId) {
    _channel?.sink.add(jsonEncode({
      "action": "join_private",
      "room_id": roomId
    }));
  }
}

// Teeme globaalse teenuse, mida saame igal pool kasutada
final socketService = WebSocketService();