import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import 'game_screen.dart'; // Lisa see import, et Navigator teaks kuhu minna
import 'waiting_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  
  @override
  void initState() {
    super.initState();
    
    // HAKKAME KUULAMA SERVERIT JUBA SIIN!
    socketService.stream.listen((data) {
      if (data['status'] == 'waiting') {
        // Kui server ütleb "start", liigume automaatselt mängu ekraanile
        if (mounted) { // Kontrollime, et ekraan on veel olemas
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WaitingScreen()),
            );
        }
      }
      else if (data['status'] == 'start') {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(
                gameId: data['game_id'],
                playerColor: data['color'],
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CHESS")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_4x4, size: 100, color: Colors.brown),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              onPressed: () {
                socketService.connect();
              },
              child: const Text("Enter the game", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}