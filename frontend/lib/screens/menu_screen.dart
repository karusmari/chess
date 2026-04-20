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

    socketService.stream.listen((data) {
      if (!mounted) return;

      if (data['status'] == 'waiting') {
        if (data['room_id'] == null && mounted) {
          final waitingPlayerId = data['your_id'] is String
              ? data['your_id'] as String
              : null;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WaitingScreen(initialPlayerId: waitingPlayerId),
            ),
          );
        }
      } else if (data['status'] == 'start') {
        if (mounted) {
          socketService.sendReady();
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

  Future<void> _handleAction(Function action, {String? roomCode}) async {
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

    action();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WaitingScreen(initialPlayerId: null, initialRoomCode: roomCode),
        ),
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
                _buildOvalButton(
                  label: "Join Public Game",
                  icon: Icons.public,
                  backgroundColor: const Color.fromARGB(255, 222, 220, 210),
                  onPressed: () =>
                      _handleAction(() => socketService.joinPublic()),
                ),
                const SizedBox(height: 20),
                _buildOvalButton(
                  label: "Create Private Game",
                  icon: Icons.lock,
                  backgroundColor: const Color.fromARGB(255, 222, 220, 210),
                  onPressed: () {
                    final roomCode = (Random().nextInt(9000) + 1000).toString();
                    _handleAction(
                      () => socketService.createPrivate(roomCode),
                      roomCode: roomCode,
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildOvalButton(
                  label: "Join Private Game",
                  icon: Icons.lock_open,
                  backgroundColor: const Color.fromARGB(255, 222, 220, 210),
                  onPressed: () {
                    setState(() {
                      _showPrivateCodeForm = true;
                    });
                  },
                ),
              ] else ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      24,
                      23,
                      21,
                    ).withOpacity(0.42),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color.fromARGB(
                        255,
                        225,
                        215,
                        170,
                      ).withOpacity(0.28),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 49, 47, 43),
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter Game Code",
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.92),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 225, 215, 170),
                              width: 1.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _resetForm,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text("Back"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.10),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(0, 42),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
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
                                      content: Text(
                                        'Please enter a game code.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.login, size: 18),
                              label: const Text("Join"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 222, 220, 210),
                                foregroundColor: const Color.fromARGB(255,49,47,43),
                                elevation: 0,
                                minimumSize: const Size(0, 42),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
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
        foregroundColor: const Color.fromARGB(255, 49, 47, 43),
        minimumSize: const Size(260, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    );
  }
}
