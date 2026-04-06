import 'package:flutter/material.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

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
            const SizedBox(height: 10),
            
            Text(
              "Your unique session is being created",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
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