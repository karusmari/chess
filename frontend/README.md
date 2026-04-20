## Frontend

### Main user flows

- Main menu supports:
  - Join Public Game
  - Create Private Game (share room code)
  - Join Private Game (enter room code)
- Waiting room supports:
  - Waiting state feedback
  - Private room code display and copy
  - Cancel button
  - 3-minute timeout countdown with auto-cancel
- Game screen supports:
  - Board orientation by player color
  - Turn indicator (`Opponent` / `You`)
  - Real-time move updates from WebSocket
  - Styled game-over dialog with winner/reason

### Notification and game-state behavior

- Player turn feedback is shown in the game screen UI.
- When game reaches terminal state, frontend receives `status: game_over` and shows game-over dialog.
- If opponent disconnects before game over, frontend shows `opponent_left` dialog.
- Redundant `opponent_left` after normal game-over is prevented.

### Key frontend files

- `lib/screens/menu_screen.dart`
- `lib/screens/waiting_screen.dart`
- `lib/screens/game_screen.dart`
- `lib/services/websocket_service.dart`

### Useful frontend commands

```bash
cd chess/frontend
flutter pub get
flutter run
```

Simulator (manual target):

```bash
flutter run -d 2B92719F-7B24-4299-B27A-0D05022F322B
```

### Note about analyzer exit code

- `flutter analyze` may return non-zero because of `info` level warnings (for example deprecated styling calls), even if app builds and runs.
