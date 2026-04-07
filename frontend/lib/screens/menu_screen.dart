import 'package:flutter/material.dart';
import 'dart:math';
import '../services/websocket_service.dart';
import 'game_screen.dart'; // Lisa see import, et Navigator teaks kuhu minna
import 'waiting_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // HAKKAME KUULAMA SERVERIT JUBA SIIN!
    socketService.stream.listen((data) {
      if (!mounted) return; // Kontrollime, et ekraan on veel olemas

      if (data['status'] == 'waiting') {
        // Kui server ütleb "start", liigume automaatselt mängu ekraanile
        if (mounted) {
          // Kontrollime, et ekraan on veel olemas
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WaitingScreen()),
          );
        }
      } else if (data['status'] == 'start') {
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
        } else if (data['status'] == 'error') {
          // Näitame veateadet, kui midagi läks valesti
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
        }
      }
    });
  }

  // Funktsioon ühendamiseks ja tegevuse saatmiseks
  void _handleAction(Function action) async {
    await socketService.connect();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CHESS")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.grid_4x4, size: 80, color: Colors.brown),
              const SizedBox(height: 40),

              // 1. AVALIK MÄNG
              ElevatedButton.icon(
                icon: const Icon(Icons.public),
                label: const Text("Join Public Game"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 60),
                ),
                onPressed: () =>
                    _handleAction(() => socketService.joinPublic()),
              ),

              const SizedBox(height: 20),
              const Divider(indent: 50, endIndent: 50),
              const SizedBox(height: 20),

              // 2. KUTSU SÕBER (Loo privaatne tuba)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_box),
                label: const Text("Create Private Room"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  minimumSize: const Size(250, 60),
                ),
                onPressed: () {
                  // Genereerime suvalise 4-kohalise koodi
                  String roomCode = (Random().nextInt(9000) + 1000).toString();
                  _handleAction(() => socketService.createPrivate(roomCode));
                },
              ),

              const SizedBox(height: 20),

              // 3. LIITU KOODIGA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: "Enter Code",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () {
                        if (_codeController.text.isNotEmpty) {
                          _handleAction(
                            () =>
                                socketService.joinPrivate(_codeController.text),
                          );
                        }
                      },
                      icon: const Icon(Icons.login),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
