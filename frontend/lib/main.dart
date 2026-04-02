import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Chess")),
        body: Center(
          child: ChessBoard(
            controller: ChessBoardController(),
            boardColor: BoardColor.brown,
            boardOrientation: PlayerColor.white,
            onMove: () {
              // Siia tuleb hiljem loogika: "Saada käik serverile"
              print("A move has been made");
            },
          ),
        ),
      ),
    );
  }
}