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
		Mu.Unlock()

		gameID := uuid.New().String()
		fmt.Printf("Game created! ID: %s\n", gameID)

		p2.Conn.WriteJSON(models.GameMessage{Status: "start", GameID: gameID, Color: "white"})
		p.Conn.WriteJSON(models.GameMessage{Status: "start", GameID: gameID, Color: "black"})

		go HandleGame(p, p2, gameID)
	}
}