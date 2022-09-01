package main

import (
	"database/sql"
	"flag"
	"fmt"

	_ "github.com/lib/pq"
)

type PGConnectionPool struct {
	db *sql.DB
}

func NewPGConnectionPool(host string, port int, user string, dbname string) (*PGConnectionPool, error) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		return nil, err
	}
	return &PGConnectionPool{db}, nil
}

func main() {
	var host = flag.String("host", "localhost", "Host of the PG database")
	var port = flag.Int("port", 5432, "Port of the PG database")
	var user = flag.String("user", "postgres", "User of the PG database")
	var dbname = flag.String("dbname", "sandrosurguladze", "DBname of the PG database")
	flag.Parse()

	connectionPool, err := NewPGConnectionPool(*host, *port, *user, *dbname)
	if err != nil {
		panic(err)
	}

	err = connectionPool.db.Ping()
	if err != nil {
		panic(err)
	}

	// Managers
	signInUpManager := NewSignInUpManager(connectionPool)
	userManager := NewUserManager(connectionPool)
	groupManager := NewGroupManager(connectionPool)
	fileManager := NewFileManager(connectionPool)
	notificationManager := NewNotificationManager(connectionPool)
	messageManager := NewMessageManager(connectionPool)
	eventManager := NewEventManager(connectionPool)
	taskManager := NewTaskManager(connectionPool)

	// Server
	server := NewServer(signInUpManager, userManager, groupManager, fileManager, notificationManager, messageManager, eventManager, taskManager)
	server.Start()
}
