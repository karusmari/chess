import 'package:flutter/material.dart';
import 'services/websocket_service.dart';
import 'screens/menu_screen.dart';
import 'screens/waiting_screen.dart'; // Loo see sarnaselt MenuScreenile
import 'screens/game_screen.dart';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainRouter(),
    );
  }
}

class MainRouter extends StatelessWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: socketService.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MenuScreen();
        }

        final data = snapshot.data!;
        
        switch (data['status']) {          
          case 'waiting':
            return const WaitingScreen();
          case 'start':
            return GameScreen(
              gameId: data['game_id'],
              playerColor: data['color'],
            );
          default:
            return const MenuScreen();
        }
      },
    );
  }
}