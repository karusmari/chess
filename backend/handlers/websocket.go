package handlers

import (
	"backend/logic"
	"backend/models"
	"fmt"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

// HandleConnections upgrades the HTTP connection to a WebSocket and processes incoming messages for matchmaking and game actions.
func HandleConnections(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println("WebSocket upgrade error:", err)
		return
	}

	player := &models.Player{ // Create a new player with a unique ID and the WebSocket connection.
		ID:   uuid.New().String(), // Generate a unique player ID using UUID.
		Conn: conn,
	}

	// waiting for the first JSON message from the client
	var initMsg map[string]string
	err = conn.ReadJSON(&initMsg)
	if err != nil {
		fmt.Println("Error reading initial message:", err)
		return
	}

	// Expecting the initial message to contain an "action" field that determines what the player wants to do.
	action := initMsg["action"]
	roomID := initMsg["room_id"] // could be empty for "join_public"
	playerID := initMsg["player_id"]

	fmt.Printf("Player %s connected with action: %s, room_id: %s\n", player.ID, action, roomID)

	// Handle the action based on the client's request
	switch action {
	case "join_public":
		logic.Matchmaking(player)
	case "cancel_waiting":
		if roomID != "" {
			logic.CancelPrivateRoomByID(roomID)
			player.Conn.WriteJSON(map[string]string{"status": "cancelled"})
			return
		}
		if playerID == "" {
			playerID = player.ID
		}
		logic.CancelWaitingByID(playerID)
		player.Conn.WriteJSON(map[string]string{"status": "cancelled"})
		return
	case "create_private":
		if roomID == "" {
			player.Conn.WriteJSON(map[string]string{"status": "error", "message": "room_id is required for create_private"})
			return
		}
		logic.CreatePrivate(player, roomID)
	case "join_private":
		if roomID == "" {
			player.Conn.WriteJSON(map[string]string{"status": "error", "message": "room_id is required for join_private"})
			return
		}
		logic.JoinPrivate(player, roomID)
	default:
		player.Conn.WriteJSON(map[string]string{"status": "error", "message": "invalid action"})
		return
	}

}
