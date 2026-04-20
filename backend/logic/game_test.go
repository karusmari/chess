package logic

import (
	"backend/models"
	"testing"

	"github.com/notnil/chess"
)

func TestBuildGameOverMessage_Checkmate(t *testing.T) {
	game := gameFromFEN(t, "rn1qkbnr/pbpp1Qpp/1p6/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 1")

	message := buildGameOverMessage(&models.Game{ChessGame: game})

	if message.Status != "game_over" {
		t.Fatalf("expected status game_over, got %q", message.Status)
	}
	if message.Winner != "white" {
		t.Fatalf("expected winner white, got %q", message.Winner)
	}
	if message.Message != "Game over. White wins by checkmate." {
		t.Fatalf("unexpected message: %q", message.Message)
	}
}

func TestBuildGameOverMessage_Stalemate(t *testing.T) {
	game := gameFromFEN(t, "k1K5/8/8/8/8/8/8/1Q6 w - - 0 1")
	if err := game.MoveStr("Qb6"); err != nil {
		t.Fatalf("expected stalemate move to be valid: %v", err)
	}

	message := buildGameOverMessage(&models.Game{ChessGame: game})

	if message.Status != "game_over" {
		t.Fatalf("expected status game_over, got %q", message.Status)
	}
	if message.Winner != "draw" {
		t.Fatalf("expected winner draw, got %q", message.Winner)
	}
	if message.Message != "Game over. Draw by stalemate." {
		t.Fatalf("unexpected message: %q", message.Message)
	}
}

func TestBuildGameOverMessage_DrawByInsufficientMaterial(t *testing.T) {
	game := gameFromFEN(t, "8/2k5/8/8/8/3K4/8/8 w - - 1 1")

	if game.Outcome() != chess.Draw {
		t.Fatalf("expected draw outcome, got %s", game.Outcome())
	}
	if game.Method() != chess.InsufficientMaterial {
		t.Fatalf("expected insufficient material, got %s", game.Method())
	}

	message := buildGameOverMessage(&models.Game{ChessGame: game})

	if message.Status != "game_over" {
		t.Fatalf("expected status game_over, got %q", message.Status)
	}
	if message.Winner != "draw" {
		t.Fatalf("expected winner draw, got %q", message.Winner)
	}
	if message.Message != "Game over. Draw by insufficient material." {
		t.Fatalf("unexpected message: %q", message.Message)
	}
}

func gameFromFEN(t *testing.T, fen string) *chess.Game {
	t.Helper()

	fenOption, err := chess.FEN(fen)
	if err != nil {
		t.Fatalf("failed to parse fen %q: %v", fen, err)
	}

	return chess.NewGame(fenOption)
}
