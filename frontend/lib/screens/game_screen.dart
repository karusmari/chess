import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import '../services/websocket_service.dart';

class GameScreen extends StatefulWidget {
  final String gameId;
  final String playerColor;

  const GameScreen({
    super.key,
    required this.gameId,
    required this.playerColor,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Loome kontrolleri siin, et see ei läheks kaduma
  final ChessBoardController _controller = ChessBoardController();
  bool _gameOverShown = false;

  @override
  void initState() {
    super.initState();

    // HAKKAME KUULAMA SERVERIT
    socketService.stream.listen((data) {
      if (data['type'] == 'move') {
        // Kui serverist tuleb uus seis (FEN), laeme selle lauale
        setState(() {
          _controller.loadFen(data['fen']);
        });
      } else if (data['status'] == 'opponent_left' && !_gameOverShown) {
        // Boonus: teavitus, kui vastane lahkub
        _showOpponentLeftDialog();
      } else if (data['status'] == 'game_over' && !_gameOverShown) {
        _gameOverShown = true;
        _showGameOverDialog(
          message: data['message']?.toString() ?? 'Game over.',
          winner: data['winner']?.toString(),
        );
      }
    });
  }

  void _showOpponentLeftDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              decoration: BoxDecoration(
                color: const ui.Color(0xFF1E2422),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const ui.Color.fromARGB(255, 222, 220, 210),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Game Over',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ui.Color(0xFFF6F0E3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Opponent left the game.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      color: ui.Color(0xFFE3D9C0),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const ui.Color.fromARGB(
                          255,
                          222,
                          220,
                          210,
                        ),
                        foregroundColor: const ui.Color.fromARGB(
                          255,
                          49,
                          47,
                          43,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Back to Menu',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGameOverDialog({required String message, String? winner}) {
    final winnerLabel = switch (winner) {
      'white' => 'Winner: White',
      'black' => 'Winner: Black',
      _ => 'Result: Draw',
    };

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              decoration: BoxDecoration(
                color: const ui.Color(0xFF1E2422),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const ui.Color.fromARGB(255, 222, 220, 210),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Game Over',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ui.Color(0xFFF6F0E3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winnerLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ui.Color.fromARGB(255, 222, 220, 210),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: ui.Color(0xFFE3D9C0),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const ui.Color.fromARGB(
                          255,
                          222,
                          220,
                          210,
                        ),
                        foregroundColor: const ui.Color.fromARGB(
                          255,
                          49,
                          47,
                          43,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Back to Menu',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text("Game: ${widget.gameId.substring(0, 8)}...")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth * 0.92
                : constraints.maxHeight * 0.62;

            // Kasutame ValueListenableBuilderit, et kuulata mängu seisu muutusi
            return ValueListenableBuilder<Chess>(
              valueListenable: _controller,
              builder: (context, game, _) {
                // KONTROLL: Kas on praeguse mängija kord?
                // game.turn väärtus on Color.WHITE või Color.BLACK
                final isWhiteTurn = game.turn == Color.WHITE;
                final isMyTurn =
                    (widget.playerColor == "white" && isWhiteTurn) ||
                    (widget.playerColor == "black" && !isWhiteTurn);
                final isOpponentTurn = !isMyTurn;
                final turnText = isWhiteTurn
                    ? "WHITE TO MOVE"
                    : "BLACK TO MOVE";

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPlayerPanel(
                          width: boardSize,
                          title: "Opponent",
                          subtitle: isOpponentTurn ? "Their move" : "Waiting",
                          isActive: isOpponentTurn,
                          activeLabel: isOpponentTurn ? turnText : null,
                          activeColor: const ui.Color.fromARGB(
                            255,
                            225,
                            215,
                            170,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // MALELAUD
                        SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: ChessBoard(
                            controller: _controller,
                            // LUKUSTAME LAUA: Lubame käike ainult siis, kui on mängija kord
                            enableUserMoves: isMyTurn,
                            boardColor: BoardColor.darkBrown,
                            boardOrientation: widget.playerColor == "white"
                                ? PlayerColor.white
                                : PlayerColor.black,
                            onMove: () {
                              final newFen = _controller.getFen();
                              socketService.sendMove(newFen);
                              print("Sent the move!");
                            },
                          ),
                        ),

                        const SizedBox(height: 14),
                        _buildPlayerPanel(
                          width: boardSize,
                          title: "You",
                          subtitle: isMyTurn ? "Your move" : "Waiting",
                          isActive: isMyTurn,
                          activeLabel: isMyTurn ? turnText : null,
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerPanel({
    required double width,
    required String title,
    required String subtitle,
    required bool isActive,
    required dynamic activeColor,
    String? activeLabel,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withOpacity(0.12)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? activeColor : Colors.black.withOpacity(0.08),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive
                        ? activeColor
                        : Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (activeLabel != null)
            _buildTurnChip(label: activeLabel, color: activeColor),
        ],
      ),
    );
  }

  Widget _buildTurnChip({required String label, required dynamic color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
