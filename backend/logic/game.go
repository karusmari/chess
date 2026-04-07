package logic

import (
	"backend/models"
	"fmt"
)

func HandleGame(p1, p2 *models.Player, game *models.Game) {
	fmt.Printf("Game %s is now active between %s and %s\n", game.ID, p1.ID, p2.ID)
	// Kanal, mille kaudu mängijad sõnumeid saadavad
	// Lisame siia juurde info, mis värvi keegi on
	go relayMoves(p1, p2, "white", game) // p1 on valge (esimene ootaja)
	go relayMoves(p2, p1, "black", game) // p2 on must
}
// currentTurn on globaalne või mängupõhine. 
// Lihtsuse mõttes teeme siia muutuja (NB! Päris süsteemis peaks see olema Game struktuuri sees)

func relayMoves(from, to *models.Player, playerColor string, game *models.Game) {
	defer func() {
        // Kui üks lahkub, kustutame mängu kaardist
        Mu.Lock()
        delete(ActiveGames, game.ID)
        Mu.Unlock()
        to.Conn.WriteJSON(map[string]string{"status": "opponent_left"})
    }()
	for {
		var msg map[string]interface{}
		err := from.Conn.ReadJSON(&msg)
		if err != nil {
			break
		}

		if msg["type"] == "move" {
			Mu.Lock()
			if playerColor != game.CurrentTurn {
				fmt.Printf("[%s] Wrong turn! %s tried to move, but it's %s's turn.\n", game.ID, playerColor, game.CurrentTurn)
				continue 
			}

			// Kui oli õige kord, vahetame korra ära
			if game.CurrentTurn == "white" {
				game.CurrentTurn = "black"
			} else {
				game.CurrentTurn = "white"
			}
			Mu.Unlock()
		}

		// Saadame sõnumi edasi vastasele
		to.Conn.WriteJSON(msg)
	}
}