package logic

import (
	"backend/models"
	"fmt"
)

func HandleGame(p1, p2 *models.Player, gameID string) {
	fmt.Printf("Game %s is now active between %s and %s\n", gameID, p1.ID, p2.ID)
	// Siia lisame hiljem for-tsükli, mis loeb käike
}