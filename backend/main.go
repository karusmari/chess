package main

import (
	"backend/handlers"
	"fmt"
	"net/http"
)

func main() {
	// Kõik WebSocketi päringud suuname handlerisse
	http.HandleFunc("/ws", handlers.HandleConnections)

	port := ":8080"
	fmt.Printf("Go server is running on %s...\n", port)
	
	err := http.ListenAndServe(port, nil)
	if err != nil {
		fmt.Printf("Server error: %v\n", err)
	}
}