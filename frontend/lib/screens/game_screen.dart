import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import '../services/websocket_service.dart'; 

class GameScreen extends StatefulWidget {
  final String gameId;
  final String playerColor;

  const GameScreen({super.key, required this.gameId, required this.playerColor});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Loome kontrolleri siin, et see ei läheks kaduma
  final ChessBoardController _controller = ChessBoardController();

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
      } else if (data['status'] == 'opponent_left') {
        // Boonus: teavitus, kui vastane lahkub
        _showOpponentLeftDialog();
      }
    });
  }

  void _showOpponentLeftDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: const Text("Opponent left the game."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Back to Menu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Game: ${widget.gameId.substring(0, 8)}..."),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double boardSize = constraints.maxWidth < constraints.maxHeight 
                ? constraints.maxWidth * 0.95 
                : constraints.maxHeight * 0.7;

            // Kasutame ValueListenableBuilderit, et kuulata mängu seisu muutusi
            return ValueListenableBuilder<Chess>(
              valueListenable: _controller,
              builder: (context, game, _) {
                // KONTROLL: Kas on praeguse mängija kord?
                // game.turn väärtus on Color.WHITE või Color.BLACK
                bool isWhiteTurn = game.turn == Color.WHITE;
                bool isMyTurn = (widget.playerColor == "white" && isWhiteTurn) ||
                                (widget.playerColor == "black" && !isWhiteTurn);

                String turnText = isWhiteTurn ? "WHITE" : "BLACK";

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "You are: ${widget.playerColor.toUpperCase()}",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      
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
                            String newFen = _controller.getFen();
                            socketService.sendMove(newFen);
                            print("Sent the move!");
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // Muudame värvi vastavalt sellele, kas on sinu kord
                          color: isMyTurn ? Colors.green.withOpacity(0.1) : Colors.brown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: isMyTurn ? Border.all(color: Colors.green, width: 2) : null,
                        ),
                        child: Text(
                          isMyTurn ? "YOUR TURN ($turnText)" : "WAITING FOR OPPONENT ($turnText)", 
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: isMyTurn ? Colors.green[700] : Colors.black87,
                          )
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}