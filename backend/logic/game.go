package logic

import (
	"backend/models"
	"fmt"
)

func HandleGame(p1, p2 *models.Player, gameID string) {
	fmt.Printf("Game %s is now active between %s and %s\n", gameID, p1.ID, p2.ID)
	// Kanal, mille kaudu mängijad sõnumeid saadavad
	// Lisame siia juurde info, mis värvi keegi on
	go relayMoves(p1, p2, "white", gameID) // p1 on valge (esimene ootaja)
	go relayMoves(p2, p1, "black", gameID) // p2 on must
}
// currentTurn on globaalne või mängupõhine. 
// Lihtsuse mõttes teeme siia muutuja (NB! Päris süsteemis peaks see olema Game struktuuri sees)
var currentTurn = "white"

func relayMoves(from, to *models.Player, playerColor string, gameID string) {
	for {
		var msg map[string]interface{}
		err := from.Conn.ReadJSON(&msg)
		if err != nil {
			break
		}

		// KONTROLL: Kas on selle mängija kord?
		if msg["type"] == "move" {
			if playerColor != currentTurn {
				fmt.Printf("[%s] Wrong turn! %s tried to move, but it's %s's turn.\n", gameID, playerColor, currentTurn)
				continue // Jätame selle sõnumi vahele, ei saada vastasele
			}

			// Kui oli õige kord, vahetame korra ära
			if currentTurn == "white" {
				currentTurn = "black"
			} else {
				currentTurn = "white"
			}
		}

		// Saadame sõnumi edasi vastasele
		to.Conn.WriteJSON(msg)
	}
}