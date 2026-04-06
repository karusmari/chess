structure

frontend/lib/
├── main.dart           # Äpi sisenemispunkt ja teema
├── screens/            # Terved ekraanid
│   ├── menu_screen.dart    # Peamenüü
│   ├── waiting_screen.dart # Ooteruum
│   └── game_screen.dart    # Malelaud ja mängu käik
├── services/           # Suhtlus välismaailmaga
│   └── websocket_service.dart # Kogu WebSocketi loogika on siin!
├── widgets/            # Korduvkasutatavad jupid
│   └── chess_board_widget.dart
└── models/             # Andmemudelid
    └── game_message.dart   # JSON-i parsimise loogika