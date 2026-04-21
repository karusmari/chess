import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../services/websocket_service.dart';
import 'game_screen.dart';

class WaitingScreen extends StatefulWidget {
  final String? initialPlayerId;
  final String? initialRoomCode;

  const WaitingScreen({super.key, this.initialPlayerId, this.initialRoomCode});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  static const int _waitingTimeoutSeconds = 180;
  static const Color _primaryTextColor = Colors.white;
  static const Color _secondaryTextColor = Color.fromARGB(255, 222, 220, 210);
  static const Color _mutedTextColor = Color.fromARGB(255, 188, 180, 158);

  static const TextStyle _titleTextStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: _primaryTextColor,
  );

  static const TextStyle _metaTextStyle = TextStyle(
    color: _secondaryTextColor,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  static const TextStyle _roomLabelTextStyle = TextStyle(
    color: _primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  static const TextStyle _roomCodeTextStyle = TextStyle(
    color: _primaryTextColor,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
  );

  static const TextStyle _bodyTextStyle = TextStyle(
    color: _mutedTextColor,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
  );

  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  Timer? _countdownTimer;
  String? _waitingPlayerId;
  String? _roomCode;
  int _secondsLeft = _waitingTimeoutSeconds;
  bool _isCancelling = false;

  void _showAccentSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color.fromARGB(255, 222, 220, 210),
        content: Text(
          message,
          style: const TextStyle(
            color: Color.fromARGB(255, 49, 47, 43),
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String get _countdownLabel {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        _secondsLeft = 0;
        _cancelWaiting(isTimeout: true);
        return;
      }

      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _waitingPlayerId = widget.initialPlayerId;
    _roomCode = widget.initialRoomCode;
    _startCountdown();
    // Listen to incoming messages from the WS server.
    // This will let us react to events like "waiting", "start", or "error" that the server sends us.
    _socketSubscription = socketService.stream.listen((data) {
      if (data['status'] == 'waiting' && data['your_id'] is String) {
        _waitingPlayerId = data['your_id'] as String;
      }
      if (data['status'] == 'waiting' && data['room_id'] is String) {
        _roomCode = data['room_id'] as String;
      }
      if (data['status'] == 'error' && mounted) {
        final errorMessage =
            data['message']?.toString() ?? 'Something went wrong.';
        _countdownTimer?.cancel();
        _showAccentSnackBar(errorMessage);
        _socketSubscription?.cancel();
        socketService.disconnect();
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      if (data['status'] == 'start' && mounted) {
        _countdownTimer?.cancel();
        socketService.sendReady();
        // Navigate to the GameScreen and pass the game ID and player color that we received from the server.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GameScreen(gameId: data['game_id'], playerColor: data['color']),
          ),
        );
      }
    });
  }

  // This method is used to cancel the waiting state.
  // It can be triggered either by the user pressing the "Cancel" button or by the countdown timer running out.
  Future<void> _cancelWaiting({bool isTimeout = false}) async {
    if (_isCancelling) return;
    _isCancelling = true;
    _countdownTimer?.cancel();

    if (_roomCode != null) {
      await socketService.cancelPrivateRoomById(_roomCode!);
    } else if (_waitingPlayerId != null) {
      await socketService.cancelWaitingById(_waitingPlayerId!);
    }
    await _socketSubscription?.cancel();
    await socketService.disconnect();
    if (!mounted) return;
    if (isTimeout) {
      _showAccentSnackBar('Waiting room timed out after 3:00.');
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // circular progress indicator while waiting for the game to start
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              strokeWidth: 6,
            ),
            const SizedBox(height: 40),

            // Title and countdown timer
            const Text("Waiting...", style: _titleTextStyle),
            const SizedBox(height: 10),
            Text("Time left: $_countdownLabel", style: _metaTextStyle),

            const SizedBox(height: 50),

            if (_roomCode != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _roomCode!),
                              );
                              if (!mounted) return;
                              _showAccentSnackBar('Room code copied');
                            },
                            icon: const Icon(Icons.copy_rounded),
                            color: Colors.white70,
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            splashRadius: 16,
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Copy code',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text("Room Code", style: _roomLabelTextStyle),
                      const SizedBox(height: 8),
                      Text(_roomCode!, style: _roomCodeTextStyle),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // description text based on whether it's a private room or public matchmaking
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _roomCode != null
                    ? "You have started a private game. Share this code with your opponent so you can play together."
                    : "The game will start as soon as we find an opponent. Please wait patiently and get ready to play some chess!",
                textAlign: TextAlign.center,
                style: _bodyTextStyle,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _cancelWaiting(),
              icon: const Icon(Icons.close),
              label: const Text("Cancel"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 222, 220, 210),
                foregroundColor: const Color.fromARGB(255, 49, 47, 43),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
