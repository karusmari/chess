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
  bool _showPrivateCodeForm = false;

  @override
  void initState() {
    super.initState();

    // HAKKAME KUULAMA SERVERIT JUBA SIIN!
    socketService.stream.listen((data) {
      if (!mounted) return; // Kontrollime, et ekraan on veel olemas

      if (data['status'] == 'waiting') {
        // Kui server ütleb "waiting", liigume ooteruumi ekraanile
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WaitingScreen()),
          );
        }
      } else if (data['status'] == 'start') {
        // Kui server ütleb "start", liigume mängu ekraanile
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
      } else if (data['status'] == 'error') {
        // Näitame veateadet, kui midagi läks valesti
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
      }
    });
  }

  void _resetForm() {
    setState(() {
      _showPrivateCodeForm = false;
      _codeController.clear();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Funktsioon ühendamiseks ja tegevuse saatmiseks
  Future<void> _handleAction(Function action) async {
    // 1. Veendu, et WebSocket on elus
    final connected = await socketService.connect();
    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not connect to the websocket server.'),
          ),
        );
      }
      return;
    }

    // 2. Tee tegevus (nt joinPublic)
    action();

    // 3. Suuna kasutaja ooteruumi (Waiting Room)
    // See on vajalik, et täita juhendi nõuet "Must have a waiting room"
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WaitingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/CHESS.png', height: 200, width: 200),
              const SizedBox(height: 10),

              if (!_showPrivateCodeForm) ...[
                // 1. JOIN PUBLIC GAME
                _buildOvalButton(
                  label: "Join Public Game",
                  icon: Icons.public,
                  backgroundColor: const Color.fromARGB(255, 126, 148, 134),
                  onPressed: () =>
                      _handleAction(() => socketService.joinPublic()),
                ),
                const SizedBox(height: 20),

                // 2. CREATE PRIVATE GAME
                _buildOvalButton(
                  label: "Create Private Game",
                  icon: Icons.lock,
                  backgroundColor: const Color.fromARGB(255, 126, 148, 134),
                  onPressed: () {
                    String roomCode = (Random().nextInt(9000) + 1000)
                        .toString();
                    _handleAction(() => socketService.createPrivate(roomCode));
                  },
                ),
                const SizedBox(height: 20),

                // 3. JOIN PRIVATE GAME (shows form on tap)
                _buildOvalButton(
                  label: "Join Private Game",
                  icon: Icons.lock_open,
                  backgroundColor: const Color.fromARGB(255, 126, 148, 134),
                  onPressed: () {
                    setState(() {
                      _showPrivateCodeForm = true;
                    });
                  },
                ),
              ] else ...[
                // FORM FOR JOINING PRIVATE GAME
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 126, 148, 134),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Enter Game Code",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: "Game Code",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.all(15),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Back"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_codeController.text.isNotEmpty) {
                                _handleAction(
                                  () => socketService.joinPrivate(
                                    _codeController.text,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a game code.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.login),
                            label: const Text("Join"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                126,
                                148,
                                134,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOvalButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(260, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    );
  }
}
