## Backend

### What the backend currently handles

- WebSocket connection upgrade and action routing (`join_public`, `create_private`, `join_private`, `cancel_waiting`).
- Public matchmaking and private room flow.
- Unique game session IDs using UUID.
- Turn enforcement (`white` starts first).
- Move relay between players in real time.
- Server-side move validation: the server checks that the received board state (FEN) is reachable from the current state by exactly one legal move.
- Terminal state detection (checkmate, stalemate, draw variants) and game-over message broadcast to both players.
- Disconnect handling (`opponent_left`) without duplicate popups after normal `game_over`.

### Key backend files

- `main.go`: starts HTTP server and exposes `/ws`.
- `handlers/websocket.go`: first-message action dispatch.
- `logic/matchmaking.go`: waiting room, private rooms, game creation.
- `logic/game.go`: move validation, relay loop, game-over logic.
- `logic/game_test.go`: tests for game-over messages and legal/illegal FEN transitions.

### Useful backend commands

```bash
cd /Users/maris.karu/Desktop/chess/backend
go mod tidy
go build ./...
go test ./logic -v
```

### Notes for demo/audit

- If `go run main.go` returns `bind: address already in use`, another backend instance is already running on port `8080`.
- For a clean rerun, stop the previous process first, then run again.
