package logic

import (
	"backend/models" // Kasuta oma mooduli nime go.mod failist!
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var (
	WaitingPlayer *models.Player
	Mu            sync.Mutex
	ActiveGames   = make(map[string]*models.Game)   // holding active games, key is game ID
	PrivateRooms  = make(map[string]*models.Player) // holding private rooms, key is room ID
)

func clearWaitingAndPrivateLocked(playerID string) {
	if WaitingPlayer != nil && WaitingPlayer.ID == playerID {
		WaitingPlayer = nil
	}

	for roomID, host := range PrivateRooms {
		if host != nil && host.ID == playerID {
			delete(PrivateRooms, roomID)
		}
	}
}

func CancelWaitingByID(playerID string) {
	if playerID == "" {
		return
	}

	Mu.Lock()
	defer Mu.Unlock()
	clearWaitingAndPrivateLocked(playerID)
}

func CancelPrivateRoomByID(roomID string) {
	if roomID == "" {
		return
	}

	Mu.Lock()
	defer Mu.Unlock()
	delete(PrivateRooms, roomID)
}

func Matchmaking(p *models.Player) {
	Mu.Lock()
	if WaitingPlayer == nil {
		WaitingPlayer = p
		Mu.Unlock()
		sendWaitingMessage(p)
	} else {
		p2 := WaitingPlayer

		// Guard against stale waiting sockets (e.g. user disconnected/cancelled earlier).
		if !isConnectionAlive(p2) {
			WaitingPlayer = p
			Mu.Unlock()
			sendWaitingMessage(p)
			return
		}

		WaitingPlayer = nil

		gameID := uuid.New().String()

		newGame := &models.Game{
			ID:          gameID,
			WhitePlayer: p2,
			BlackPlayer: p,
			CurrentTurn: "white",
		}
		ActiveGames[gameID] = newGame // saving the game to active games map
		Mu.Unlock()

		fmt.Printf("Game created! ID: %s\n", gameID)

		if err := p2.Conn.WriteJSON(models.GameMessage{Status: "start", GameID: gameID, Color: "white"}); err != nil {
			// Old waiting player was stale. Requeue the new player instead of starting a broken game.
			Mu.Lock()
			delete(ActiveGames, gameID)
			WaitingPlayer = p
			Mu.Unlock()
			sendWaitingMessage(p)
			return
		}

		if err := p.Conn.WriteJSON(models.GameMessage{Status: "start", GameID: gameID, Color: "black"}); err != nil {
			// New joiner disconnected. Put the previous waiting player back if still alive.
			Mu.Lock()
			delete(ActiveGames, gameID)
			if isConnectionAlive(p2) {
				WaitingPlayer = p2
			} else {
				WaitingPlayer = nil
			}
			Mu.Unlock()

			if WaitingPlayer == p2 {
				sendWaitingMessage(p2)
			}
			return
		}

		// Wait for both players to confirm they're ready before starting the game loop.
		if !waitForReady(p2) {
			Mu.Lock()
			delete(ActiveGames, gameID)
			WaitingPlayer = p
			Mu.Unlock()
			sendWaitingMessage(p)
			return
		}

		if !waitForReady(p) {
			Mu.Lock()
			delete(ActiveGames, gameID)
			if isConnectionAlive(p2) {
				WaitingPlayer = p2
			} else {
				WaitingPlayer = nil
			}
			Mu.Unlock()

			if WaitingPlayer == p2 {
				sendWaitingMessage(p2)
			}
			return
		}

		go HandleGame(p2, p, newGame)
	}
}

func sendWaitingMessage(p *models.Player) {
	p.Conn.WriteJSON(models.GameMessage{
		Status:  "waiting",
		Message: "Waiting for opponent...",
		YourID:  p.ID,
	})
}

func isConnectionAlive(p *models.Player) bool {
	if p == nil || p.Conn == nil {
		return false
	}

	err := p.Conn.WriteControl(
		websocket.PingMessage,
		[]byte("ping"),
		time.Now().Add(1*time.Second),
	)

	return err == nil
}

func waitForReady(p *models.Player) bool {
	if p == nil || p.Conn == nil {
		return false
	}

	_ = p.Conn.SetReadDeadline(time.Now().Add(5 * time.Second))
	defer p.Conn.SetReadDeadline(time.Time{})

	for {
		var msg map[string]interface{}
		if err := p.Conn.ReadJSON(&msg); err != nil {
			return false
		}

		msgType, _ := msg["type"].(string)
		if msgType == "ready" {
			return true
		}
	}
}

// CreatePrivate ootab sõpra konkreetse koodiga
func CreatePrivate(p *models.Player, roomID string) {
	Mu.Lock()
	PrivateRooms[roomID] = p
	Mu.Unlock()

	p.Conn.WriteJSON(models.GameMessage{
		Status:  "waiting",
		Message: "Invite your friend with code: " + roomID,
		RoomID:  roomID,
	})
}

// JoinPrivate kontrollib, kas selline kood on ootel
func JoinPrivate(p *models.Player, roomID string) {
	Mu.Lock()
	host, exists := PrivateRooms[roomID]

	if !exists {
		Mu.Unlock()
		p.Conn.WriteJSON(models.GameMessage{Status: "error", Message: "Room not found!"})
		return
	}

	// Kui leiti, kustutame ooteruumist ja loome mängu
	delete(PrivateRooms, roomID)

	gameID := uuid.New().String()
	newGame := &models.Game{
		ID:          gameID,
		WhitePlayer: host, // Kutsuja on valge
		BlackPlayer: p,    // Liituja on must
		CurrentTurn: "white",
	}
	ActiveGames[gameID] = newGame // SALVESTAME AKTIIVSETE MÄNGUDE ALLA
	Mu.Unlock()

	// Saadame mõlemale start-sõnumi
	host.Conn.WriteJSON(models.GameMessage{Status: "start", GameID: gameID, Color: "white"})
	p.Conn.WriteJSON(models.GameMessage{Status: "start", GameID: gameID, Color: "black"})

	go HandleGame(host, p, newGame)
}
