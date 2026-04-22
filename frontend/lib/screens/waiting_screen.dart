import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../services/websocket_service.dart';
import 'game_screen.dart';
import 'menu_screen.dart';

class WaitingScreen extends StatefulWidget {
  final String? initialPlayerId;
  final String? initialRoomCode;

  const WaitingScreen({super.key, this.initialPlayerId, this.initialRoomCode});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  // constants and styling 
  static const int _waitingTimeoutSeconds = 180;
  static const Color _primaryTextColor = Colors.white;
  static const Color _secondaryTextColor = Color.fromARGB(255, 222, 220, 210);
  static const Color _mutedTextColor = Color.fromARGB(255, 188, 180, 158);

  static const TextStyle _titleTextStyle = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: _primaryTextColor,
  );
  static const TextStyle _metaTextStyle = TextStyle(
    color: _secondaryTextColor, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.6,
  );
  static const TextStyle _roomCodeTextStyle = TextStyle(
    color: _primaryTextColor, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 2.0,
  );
  static const TextStyle _bodyTextStyle = TextStyle(
    color: _mutedTextColor, fontSize: 15, fontWeight: FontWeight.w400, height: 1.4, letterSpacing: 0.2,
  );

  // state variables
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  Timer? _countdownTimer;
  String? _waitingPlayerId;
  String? _roomCode;
  int _secondsLeft = _waitingTimeoutSeconds;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _waitingPlayerId = widget.initialPlayerId;
    _roomCode = widget.initialRoomCode;
    _startCountdown();
    _initSocketListener();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socketSubscription?.cancel();
    super.dispose();
  }

  // socket connection and communication methods

  void _initSocketListener() {
    _socketSubscription = socketService.stream.listen((data) {
      if (!mounted) return;

      setState(() {
        if (data['status'] == 'waiting') {
          if (data['your_id'] is String) _waitingPlayerId = data['your_id'];
          if (data['room_id'] is String) _roomCode = data['room_id'];
        }
      });

      if (data['status'] == 'error') {
        _handleError(data['message']?.toString() ?? 'Something went wrong.');
      } else if (data['status'] == 'start') {
        _startGame(data);
      }
    });
  }

  void _handleError(String message) {
    _countdownTimer?.cancel();
    _showAccentSnackBar(message);
    _exitToMenu();
  }

  void _startGame(Map<String, dynamic> data) {
    _countdownTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          gameId: data['game_id'], 
          playerColor: data['color']
        ),
      ),
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _cancelWaiting(isTimeout: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _cancelWaiting({bool isTimeout = false}) async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    _countdownTimer?.cancel();

    if (_roomCode != null) {
      await socketService.cancelPrivateRoomById(_roomCode!);
    } else if (_waitingPlayerId != null) {
      await socketService.cancelWaitingById(_waitingPlayerId!);
    }
    
    if (isTimeout) _showAccentSnackBar('Waiting room timed out after 3:00.');
    _exitToMenu();
  }

  void _exitToMenu() {
    _socketSubscription?.cancel();
    socketService.disconnect();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (route) => false,
    );
  }

  // UI components 

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
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildLoadingSection(),
              const Spacer(flex: 1),
              if (_roomCode != null) _buildRoomCodeBox(),
              _buildInfoText(),
              const Spacer(flex: 2),
              _buildCancelButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                strokeWidth: 3,
              ),
            ),
            Icon(Icons.hourglass_empty_rounded, 
                 color: Colors.white.withOpacity(0.15), size: 35),
          ],
        ),
        const SizedBox(height: 40),
        const Text("Waiting for Opponent", style: _titleTextStyle),
        const SizedBox(height: 10),
        Text("Time left: $_countdownLabel", style: _metaTextStyle),
      ],
    );
  }

  Widget _buildRoomCodeBox() {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: _roomCode!));
        _showAccentSnackBar('Room code copied');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 30, left: 40, right: 40),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Text("ROOM CODE", 
                style: TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 24), // Ikooni tasakaalustamiseks
                Text(_roomCode!, style: _roomCodeTextStyle),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, color: Colors.white24, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Text(
        _roomCode != null
            ? "You have started a private game. Share this code with your opponent so you can play together."
            : "The game will start as soon as we find an opponent. Please wait patiently and get ready!",
        textAlign: TextAlign.center,
        style: _bodyTextStyle,
      ),
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton.icon(
      onPressed: _isCancelling ? null : () => _cancelWaiting(),
      icon: const Icon(Icons.close),
      label: const Text("Cancel"),
      style: ElevatedButton.styleFrom(
        backgroundColor: _secondaryTextColor,
        foregroundColor: const Color.fromARGB(255, 49, 47, 43),
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
    );
  }

  // helper methods

  String get _countdownLabel {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showAccentSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _secondaryTextColor,
        duration: const Duration(seconds: 2),
        content: Text(
          message,
          style: const TextStyle(color: Color.fromARGB(255, 49, 47, 43), fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}