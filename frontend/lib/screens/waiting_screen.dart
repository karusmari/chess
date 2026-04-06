import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import 'game_screen.dart'; // Lisa see import, et Navigator teaks kuhu minna

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  @override
  void initState() {
    super.initState();
    // KUULAME SERVERIT: Kui keegi teine liitub, saadetakse "start"
    socketService.stream.listen((data) {
      print("WaitingScreen received data: $data");
      if (data['status'] == 'start' && mounted) {
        // Liigume mängu ekraanile ja eemaldame oote-ekraani ajaloost
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              gameId: data['game_id'],
              playerColor: data['color'],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Teeme väikse gradiendi, et näeks "proffim" välja
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tiirutav laadimisikoon
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              strokeWidth: 6,
            ),
            const SizedBox(height: 40),
            
            // Tekst kasutajale
            const Text(
              "Waiting...",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Väike "Abimees" tekst
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "The game will start as soon as we find an opponent. Please wait patiently and get ready to play some chess!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}