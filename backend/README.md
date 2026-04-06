Starting to make the project 
go mod init backend
go get github.com/google/uuid
go get github.com/gorilla/websocket

structure

backend/
├── main.go             # Ainult serveri käivitamine ja ruutimine
├── go.mod              # Sõltuvused
├── handlers/           # HTTP ja WebSocketi ühenduste haldus
│   └── websocket.go    # Upgrade'imine ja esmane ühendus
├── logic/              # Mängu sisu (see "aju")
│   ├── manager.go      # Matchmaking ja ooteruum
│   ├── game.go         # Käikude edastamine kahe mängija vahel
│   └── models.go       # Structid: Player, Game, Message (JSON kuju)
└── utils/              # Abifunktsioonid (nt UUID genereerimine)