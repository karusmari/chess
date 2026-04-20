package logic

import (
	"backend/models"
	"fmt"

	"github.com/notnil/chess"
)

func HandleGame(p1, p2 *models.Player, game *models.Game) {
	fmt.Printf("Game %s is now active between %s and %s\n", game.ID, p1.ID, p2.ID)
	if game.ChessGame == nil {
		game.ChessGame = chess.NewGame()
	}
	// Kanal, mille kaudu mängijad sõnumeid saadavad
	// Lisame siia juurde info, mis värvi keegi on
	go relayMoves(p1, p2, "white", game) // p1 on valge (esimene ootaja)
	go relayMoves(p2, p1, "black", game) // p2 on must
}

// currentTurn on globaalne või mängupõhine.
// Lihtsuse mõttes teeme siia muutuja (NB! Päris süsteemis peaks see olema Game struktuuri sees)

func relayMoves(from, to *models.Player, playerColor string, game *models.Game) {
	defer func() {
		// Only send opponent_left when the game is still active.
		// If game_over already happened, ActiveGames no longer contains this game.
		Mu.Lock()
		_, isActive := ActiveGames[game.ID]
		if isActive {
			delete(ActiveGames, game.ID)
		}
		Mu.Unlock()

		if isActive {
			to.Conn.WriteJSON(map[string]string{"status": "opponent_left"})
		}
	}()
	for {
		var msg map[string]interface{}
		err := from.Conn.ReadJSON(&msg)
		if err != nil {
			break
		}

		if msg["type"] == "move" {
			fen, _ := msg["fen"].(string)
			fenOption, fenErr := chess.FEN(fen)
			if fenErr != nil {
				fmt.Printf("[%s] Invalid FEN received: %v\n", game.ID, fenErr)
				continue
			}
			updatedGame := chess.NewGame(fenOption)

			Mu.Lock()
			if playerColor != game.CurrentTurn {
				fmt.Printf("[%s] Wrong turn! %s tried to move, but it's %s's turn.\n", game.ID, playerColor, game.CurrentTurn)
				Mu.Unlock()
				continue
			}
			game.ChessGame = updatedGame

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

		if msg["type"] == "move" {
			Mu.Lock()
			finished := game.ChessGame != nil && game.ChessGame.Outcome() != chess.NoOutcome
			gameOverMsg := models.GameMessage{}
			if finished {
				// Mark game as finished before returning so deferred cleanup does not emit opponent_left.
				gameOverMsg = buildGameOverMessage(game)
				delete(ActiveGames, game.ID)
			}
			Mu.Unlock()

			if finished {
				from.Conn.WriteJSON(gameOverMsg)
				to.Conn.WriteJSON(gameOverMsg)
				return
			}
		}
	}
}

func buildGameOverMessage(game *models.Game) models.GameMessage {
	winner := "draw"
	message := "Game over. Draw."

	if game == nil || game.ChessGame == nil {
		return models.GameMessage{Status: "game_over", Winner: winner, Message: message}
	}

	switch game.ChessGame.Outcome() {
	case chess.WhiteWon:
		winner = "white"
		message = "Game over. White wins by " + formatOutcomeMethod(game.ChessGame.Method()) + "."
	case chess.BlackWon:
		winner = "black"
		message = "Game over. Black wins by " + formatOutcomeMethod(game.ChessGame.Method()) + "."
	case chess.Draw:
		winner = "draw"
		method := formatOutcomeMethod(game.ChessGame.Method())
		if method == "" || method == "No method" {
			message = "Game over. Draw."
		} else {
			message = "Game over. Draw by " + method + "."
		}
	}

	return models.GameMessage{
		Status:  "game_over",
		Winner:  winner,
		Method:  game.ChessGame.Method().String(),
		Message: message,
	}
}

func formatOutcomeMethod(method chess.Method) string {
	switch method {
	case chess.Checkmate:
		return "checkmate"
	case chess.Stalemate:
		return "stalemate"
	case chess.InsufficientMaterial:
		return "insufficient material"
	case chess.ThreefoldRepetition:
		return "threefold repetition"
	case chess.FivefoldRepetition:
		return "fivefold repetition"
	case chess.FiftyMoveRule:
		return "fifty-move rule"
	case chess.SeventyFiveMoveRule:
		return "seventy-five move rule"
	case chess.DrawOffer:
		return "draw offer"
	case chess.Resignation:
		return "resignation"
	default:
		return ""
	}
}
