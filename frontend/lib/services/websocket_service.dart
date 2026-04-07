import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  
  // StreamController võimaldab meil saata andmeid mitmele ekraanile korraga
  final StreamController<Map<String, dynamic>> _controller = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void connect() {
    _channel?.sink.close(); // Sulgeme vana ühenduse, kui see olemas on

    // Chrome'i jaoks localhost, emulaatori jaoks 10.0.2.2
    final uri = Uri.parse('ws://localhost:8080/ws'); // IP 192.168.1.73
    print("Connecting to $uri...");

    try {
    _channel = WebSocketChannel.connect(uri);

   _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        print("WEB SOCKETS MESSAGE: $data"); // <--- SEE ON KRIITILINE LOGI
        
        // Saadame andmed edasi kontrollerisse, mida ekraanid kuulavad
        _controller.add(data);
      },
      onError: (error) {
        print("WebSockets error: $error");
        _controller.add({"status": "error", "message": error.toString()});
      },
      onDone: () {
        print("WebSockets connection closed");
        _controller.add({"status": "disconnected"});
      },
      cancelOnError: true,
    );
  } catch (e) {
    print("Error connecting to WebSocket: $e");
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
}

// Teeme globaalse teenuse, mida saame igal pool kasutada
final socketService = WebSocketService();