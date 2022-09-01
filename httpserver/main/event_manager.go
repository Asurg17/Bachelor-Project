package main

import (
	"errors"
)

type EventManager struct {
	connectionPool *PGConnectionPool
}

func NewEventManager(connectionPool *PGConnectionPool) *EventManager {
	eventManager := new(EventManager)
	eventManager.connectionPool = connectionPool
	return eventManager
}

// Manager Functions

func (m *EventManager) createNewEvent(params CreateNewEventParams) error {
	if !isUserValid(params.UserId, m.connectionPool.db) {
		return errors.New("can't search new groups. user not valid")
	}

	insertQuery := `insert into events(creator_user_id, in_group_id, event_title, event_place, 
									event_type, event_description, event_date, event_time, formatted_date, event_key)
					values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);`

	_, err := m.connectionPool.db.Exec(insertQuery, params.UserId, params.GroupId, params.EventName, params.Place, "in_group",
		params.EventDescription, params.Date, params.Time, params.FormattedDate, params.EventUniqueKey)
	if err != nil {
		return err
	}

	return nil
}
