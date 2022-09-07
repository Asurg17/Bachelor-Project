package main

type SharedManager struct {
	connectionPool *PGConnectionPool
}

func NewSharedManager(connectionPool *PGConnectionPool) *SharedManager {
	sharedManager := new(SharedManager)
	sharedManager.connectionPool = connectionPool
	return sharedManager
}

// Manager Functions

func (m *SharedManager) isUserValid(userId string) bool {
	if userId == "" {
		return false
	}

	getQuery := `select s.user_id
				from users s
				where s.user_id = $1;`

	var id string
	return m.connectionPool.db.QueryRow(getQuery, userId).Scan(&id) == nil
}
