package models

import (
	"github.com/gorilla/websocket"
	"github.com/notnil/chess"
)

type Player struct {
	ID   string
	Conn *websocket.Conn
}

type GameMessage struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
	GameID  string `json:"game_id,omitempty"`
	RoomID  string `json:"room_id,omitempty"`
	Color   string `json:"color,omitempty"`
	YourID  string `json:"your_id,omitempty"`
	Winner  string `json:"winner,omitempty"`
	Method  string `json:"method,omitempty"`
}

type Game struct {
	ID          string
	WhitePlayer *Player
	BlackPlayer *Player
	CurrentTurn string // "white" or "black"
	ChessGame   *chess.Game
}
