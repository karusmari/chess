package models

import "github.com/gorilla/websocket"

type Player struct {
	ID   string
	Conn *websocket.Conn
}

type GameMessage struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
	GameID  string `json:"game_id,omitempty"`
	Color   string `json:"color,omitempty"`
	YourID  string `json:"your_id,omitempty"`
}

type Game struct {
    ID          string
    WhitePlayer *Player
    BlackPlayer *Player
    CurrentTurn string // "white" or "black"
}