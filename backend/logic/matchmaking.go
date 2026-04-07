package logic

import (
	"backend/models" // Kasuta oma mooduli nime go.mod failist!
	"fmt"
	"sync"
	"github.com/google/uuid"
)

var (
	WaitingPlayer *models.Player
	Mu            sync.Mutex
	ActiveGames = make(map[string]*models.Game) // holding active games, key is game ID
	PrivateRooms = make(map[string]*models.Player) // holding private rooms, key is room ID
)

func Matchmaking(p *models.Player) {
	Mu.Lock()
	if WaitingPlayer == nil {
		WaitingPlayer = p
		Mu.Unlock()
		p.Conn.WriteJSON(models.GameMessage{
			Status: "waiting",
			Message: "Waiting for opponent...",
			YourID: p.ID,
		})
	} else {
		p2 := WaitingPlayer
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

		p2.Conn.WriteJSON(models.GameMessage{Status: "start", GameID: gameID, Color: "white"})
		p.Conn.WriteJSON(models.GameMessage{Status: "start", GameID: gameID, Color: "black"})

		go HandleGame(p2, p, newGame)
	}
}

// CreatePrivate ootab sõpra konkreetse koodiga
func CreatePrivate(p *models.Player, roomID string) {
	Mu.Lock()
	PrivateRooms[roomID] = p
	Mu.Unlock()
	
	p.Conn.WriteJSON(models.GameMessage{
		Status:  "waiting",
		Message: "Kutsu sõber koodiga: " + roomID,
	})
}

// JoinPrivate kontrollib, kas selline kood on ootel
func JoinPrivate(p *models.Player, roomID string) {
	Mu.Lock()
	host, exists := PrivateRooms[roomID]
	
	if !exists {
		Mu.Unlock()
		p.Conn.WriteJSON(models.GameMessage{Status: "error", Message: "Tuba ei leitud!"})
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