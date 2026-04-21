package main

import (
	"backend/handlers"
	"fmt"
	"net/http"
)

func main() {
	// All the WebSocket connections will be handled by the HandleConnections function in the handlers package.
	http.HandleFunc("/ws", handlers.HandleConnections)

	port := ":8080"
	fmt.Printf("Go server is running on %s...\n", port)
	
	err := http.ListenAndServe(port, nil)
	if err != nil {
		fmt.Printf("Server error: %v\n", err)
	}
}