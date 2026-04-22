package logic

import (
	"backend/models"
	"fmt"
	"strings"

	"github.com/notnil/chess"
)

// HandleGame manages the game loop between two players, relaying moves and handling game over conditions.
func HandleGame(p1, p2 *models.Player, game *models.Game) {
	fmt.Printf("Game %s is now active between %s and %s\n", game.ID, p1.ID, p2.ID)
	if game.ChessGame == nil {
		game.ChessGame = chess.NewGame()
	}
	// Start one relay goroutine per player direction and keep color info per relay.
	go relayMoves(p1, p2, "white", game) // p1 is white.
	go relayMoves(p2, p1, "black", game) // p2 is black.
}

// relayMoves continuously reads moves from one player and forwards them to the opponent, while also checking for game over conditions after each move.
func relayMoves(from, to *models.Player, playerColor string, game *models.Game) {
	defer func() { // Clean up game and notify opponent if a player disconnects.
		Mu.Lock()
		clearWaitingAndPrivateLocked(from.ID)
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
			if strings.TrimSpace(fen) == "" {
				from.Conn.WriteJSON(map[string]string{"status": "error", "message": "Move payload is missing FEN"})
				continue
			}

			var acceptedFEN string

			Mu.Lock()
			if playerColor != game.CurrentTurn {
				fmt.Printf("[%s] Wrong turn! %s tried to move, but it's %s's turn.\n", game.ID, playerColor, game.CurrentTurn)
				Mu.Unlock()
				continue
			}

			updatedGame, transitionErr := verifyFENTransition(game.ChessGame, fen)
			if transitionErr != nil {
				Mu.Unlock()
				fmt.Printf("[%s] Illegal move transition: %v\n", game.ID, transitionErr)
				from.Conn.WriteJSON(map[string]string{"status": "error", "message": "Illegal move"})
				continue
			}
			game.ChessGame = updatedGame
			acceptedFEN = game.ChessGame.FEN()

			// Valid move: switch turn to the other color.
			if game.CurrentTurn == "white" {
				game.CurrentTurn = "black"
			} else {
				game.CurrentTurn = "white"
			}
			Mu.Unlock()

			// Forward the canonical server FEN, not raw client input.
			msg["fen"] = acceptedFEN
		}

		// Forward the move payload to the opponent.
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

// verifyFENTransition checks whether targetFEN is reachable from current by exactly one legal move.
func verifyFENTransition(current *chess.Game, targetFEN string) (*chess.Game, error) {
	if current == nil {
		return nil, fmt.Errorf("current game is nil")
	}

	targetOption, err := chess.FEN(targetFEN)
	if err != nil {
		return nil, fmt.Errorf("invalid target FEN: %w", err)
	}
	targetGame := chess.NewGame(targetOption)
	targetKey := fenComparableKey(targetGame.FEN())

	for _, move := range current.ValidMoves() {
		candidate := current.Clone()
		if moveErr := candidate.Move(move); moveErr != nil {
			continue
		}

		if fenComparableKey(candidate.FEN()) == targetKey {
			return candidate, nil
		}
	}

	return nil, fmt.Errorf("target FEN is not reachable by one legal move")
}

// fenComparableKey compares board-relevant FEN parts and ignores move counters.
func fenComparableKey(fen string) string {
	parts := strings.Fields(strings.TrimSpace(fen))
	if len(parts) < 4 {
		return strings.TrimSpace(fen)
	}

	return strings.Join(parts[:4], " ")
}

// buildGameOverMessage constructs a GameMessage with the appropriate status, winner, and message based on the final state of the chess game.
// these are the messages client sees 
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

// formatOutcomeMethod converts a chess.Method to a human-readable string for game over messages.
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
