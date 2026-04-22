import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'menu_screen.dart';
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
  // Controls board state and allows reading/updating FEN from UI changes.
  final ChessBoardController _controller = ChessBoardController();
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  // Prevents showing duplicate end-of-game dialogs from multiple socket events.
  bool _gameOverShown = false;

  Future<void> _leaveGame() async {
    if (_gameOverShown) return;
    _gameOverShown = true;

    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await socketService.disconnect();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();

    // Listen to real-time server events for this game session.
    _socketSubscription = socketService.stream.listen((data) {
      if (data['type'] == 'move') {
        // Server sends the canonical FEN after each valid move.
        setState(() {
          _controller.loadFen(data['fen']);
        });
      } else if (data['status'] == 'opponent_left' && !_gameOverShown) {
        // Show a final dialog if the opponent disconnects before game_over.
        _showOpponentLeftDialog();
      } else if (data['status'] == 'game_over' && !_gameOverShown) {
        // Show exactly one final result dialog.
        _gameOverShown = true;
        _showGameOverDialog(
          message: data['message']?.toString() ?? 'Game over.',
          winner: data['winner']?.toString(),
        );
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    // Leaving the game screen should close the live game socket.
    // This allows backend to notify the opponent that this player left.
    socketService.disconnect();
    super.dispose();
  }

  void _showOpponentLeftDialog() {
    // Uses the same visual style as game-over dialog for consistency.
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
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MenuScreen()),
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const ui.Color.fromARGB(255,222,220,210),
                        foregroundColor: const ui.Color.fromARGB(255,49,47,43),
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
    // Translate backend winner value into a user-friendly label.
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
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MenuScreen()),
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const ui.Color.fromARGB(255,222,220,210),
                        foregroundColor: const ui.Color.fromARGB(255,49,47,43),
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

            // Rebuild player indicators when board turn/state changes.
            return ValueListenableBuilder<Chess>(
              valueListenable: _controller,
              builder: (context, game, _) {
                // Determine whose turn it is and whether local player may move.
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
                          isActive: isOpponentTurn,
                          activeLabel: turnText,
                          showActiveChip: isOpponentTurn,
                          activeColor: const ui.Color.fromARGB(255,225,215,170),
                        ),
                        const SizedBox(height: 14),

                        // Main chess board.
                        SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: ChessBoard(
                            controller: _controller,
                            // Client-side guard: local user can move only on own turn.
                            enableUserMoves: isMyTurn,
                            boardColor: BoardColor.darkBrown,
                            boardOrientation: widget.playerColor == "white"
                                ? PlayerColor.white
                                : PlayerColor.black,
                            onMove: () {
                              // Send updated board state to backend for validation.
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
                          isActive: isMyTurn,
                          activeLabel: turnText,
                          showActiveChip: isMyTurn,
                          activeColor: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: boardSize,
                          child: OutlinedButton.icon(
                            onPressed: _leaveGame,
                            icon: const Icon(Icons.exit_to_app_rounded),
                            label: const Text('Leave Game'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const ui.Color.fromARGB(255,222,220,210),
                              side: const BorderSide(
                                color: ui.Color.fromARGB(255, 222, 220, 210),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
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
    required bool isActive,
    required dynamic activeColor,
    required String activeLabel,
    required bool showActiveChip,
  }) {
    const panelBorderColor = ui.Color.fromARGB(255, 222, 220, 210);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? const ui.Color.fromARGB(255, 222, 220, 210).withOpacity(0.08)
            : const ui.Color.fromARGB(255, 222, 220, 210).withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelBorderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: ui.Color(0xFFF6F0E3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: ui.Color(0xFFF6F0E3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildTurnChip(
            label: activeLabel,
            color: activeColor,
            isVisible: showActiveChip,
          ),
        ],
      ),
    );
  }

  Widget _buildTurnChip({
    required String label,
    required dynamic color,
    required bool isVisible,
  }) {
    return Opacity(
      opacity: isVisible ? 1 : 0,
      child: Container(
        width: 144,
        alignment: Alignment.center,
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
      ),
    );
  }
}
