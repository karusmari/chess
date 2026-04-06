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
            // Arvutame optimaalse suuruse
            double boardSize = constraints.maxWidth < constraints.maxHeight 
                ? constraints.maxWidth * 0.95 // Portreevaates peaaegu täislaius
                : constraints.maxHeight * 0.7; // Maastikuvaates jääb ruumi tekstile

            return Center( // Hoiame kogu sisu ekraani keskel
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
                  ValueListenableBuilder<Chess>(
                    valueListenable: _controller,
                    builder: (context, game, _) {
                      String turn = game.turn == Color.WHITE ? "WHITE" : "BLACK";
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "It's $turn's turn", 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}