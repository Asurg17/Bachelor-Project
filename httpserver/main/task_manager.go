package main

import "errors"

type TaskManager struct {
	connectionPool *PGConnectionPool
}

func NewTaskManager(connectionPool *PGConnectionPool) *TaskManager {
	taskManager := new(TaskManager)
	taskManager.connectionPool = connectionPool
	return taskManager
}

// Manager Functions

func (m *TaskManager) createNewTask(params CreateNewTaskParams) error {
	if !isUserValid(params.UserId, m.connectionPool.db) {
		return errors.New("can't search new groups. user not valid")
	}

	insertQuery := `insert into events(creator_user_id, in_group_id, event_title, event_place, 
									event_type, event_description, event_date, event_time, formatted_date, event_key)
					values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);`

	_, err := m.connectionPool.db.Exec(insertQuery)
	if err != nil {
		return err
	}

	return nil
}
