package handlers

import (
	"backend/logic"
	"backend/models"
	"net/http"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func HandleConnections(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	player := &models.Player{
		ID:   uuid.New().String(),
		Conn: conn,
	}

	logic.Matchmaking(player)
}