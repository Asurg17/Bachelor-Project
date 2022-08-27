package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
)

type SignInUpManager struct {
	connectionPool *PGConnectionPool
}

func NewSignInUpManager(connectionPool *PGConnectionPool) *SignInUpManager {
	signInUpManager := new(SignInUpManager)
	signInUpManager.connectionPool = connectionPool
	return signInUpManager
}

// Manager Functions

func (m *SignInUpManager) registerNewUser(username string, password string, firstName string, lastName string, phoneNumber string) (map[string]string, error) {
	passwordHash := sha256.New()
	passwordHash.Write([]byte(password))
	passwordMd := passwordHash.Sum(nil)
	passwordMdStr := hex.EncodeToString(passwordMd)

	userId := username + passwordMdStr

	insertQuery := `insert into "users" ("username", "password", "first_name", "last_name", "user_id", "phone")
					values ($1, $2, $3, $4, $5, $6)`
	_, err := m.connectionPool.db.Exec(insertQuery, username, passwordMdStr, firstName, lastName, userId, phoneNumber)
	if err != nil {
		return nil, err
	}

	response := make(map[string]string)
	response["userId"] = userId

	return response, nil
}

func (m *SignInUpManager) validateUser(username string, password string) (map[string]string, error) {
	var actualPassword string
	var userId string
	getQuery := `select s.password, s.user_id from users s where s.username = $1`
	if err := m.connectionPool.db.QueryRow(getQuery, username).Scan(&actualPassword, &userId); err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.New("no such username")
		}
		return nil, err
	}

	hash := sha256.New()
	hash.Write([]byte(password))
	md := hash.Sum(nil)
	mdStr := hex.EncodeToString(md)

	if mdStr != actualPassword {
		return nil, errors.New("incorrect password")
	}

	response := make(map[string]string)
	response["userId"] = userId

	return response, nil
}
