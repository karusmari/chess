import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class GameScreen extends StatelessWidget {
  final String gameId;
  final String playerColor;

  const GameScreen({super.key, required this.gameId, required this.playerColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Game: $gameId")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("You are: $playerColor", style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          ChessBoard(
            controller: ChessBoardController(),
            boardColor: BoardColor.brown,
            boardOrientation: playerColor == "white" ? PlayerColor.white : PlayerColor.black,
            onMove: () => print("You moved!"),
          ),
        ],
      ),
    );
  }
}