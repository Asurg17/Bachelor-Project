package main

import (
	"database/sql"
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

func (m *EventManager) getEvents(params GetEventsParams) (map[string][]map[string]string, error) {
	if !isUserValid(params.UserId, m.connectionPool.db) {
		return nil, errors.New("can't search new groups. user not valid")
	}

	getQuery := ``
	queryParam := params.UserId

	if len(params.GroupId) != 0 {
		queryParam = params.GroupId
		getQuery = `select e.event_key,
							e.creator_user_id,
							coalesce(e.to_user_id, '') user_id,
							coalesce(e.group_id, '') group_id,
							(case when e.to_user_id is null
							then (select group_title
								from groups g
								where g.group_id = e.group_id)
							when e.to_user_id = $2 then 
							(select u.first_name || ' ' || u.last_name
									from users u
								where u.user_id = e.creator_user_id)
							else (select u.first_name || ' ' || u.last_name
									from users u
								where u.user_id = e.to_user_id) end) event_header,
							e.event_title,
							coalesce(e.event_description, '') eventDescription,
							e.event_place,
							e.event_type,
							e.event_date,
							coalesce(e.event_time, '-:-') event_time
					from events e
					where e.group_id = $1
					and e.formatted_date >= $3
					order by e.formatted_date, (case when e.event_time = '-:-' then 2 else 1 end);`
	} else {
		getQuery = `select e.event_key,
							e.creator_user_id,
							coalesce(e.to_user_id, '') user_id,
							coalesce(e.group_id, '') group_id,
							(case when e.to_user_id is null
							then (select group_title
								from groups g
								where g.group_id = e.group_id)
							when e.to_user_id = $2 then 
								(select u.first_name || ' ' || u.last_name
									from users u
									where u.user_id = e.creator_user_id)
							else (select u.first_name || ' ' || u.last_name
									from users u
								where u.user_id = e.to_user_id) end) event_header,
							e.event_title,
							coalesce(e.event_description, '') eventDescription,
							e.event_place,
							e.event_type,
							e.event_date,
							coalesce(e.event_time, '-:-') event_time
					from events e
					where e.to_user_id = $1 
						or e.group_id in (select group_id
											from group_members 
										where user_id = $1)
					and e.formatted_date >= $3
					order by e.formatted_date, (case when e.event_time = '-:-' then 2 else 1 end);`
	}

	rows, err := m.connectionPool.db.Query(getQuery, queryParam, params.UserId, params.CurrentDate)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	events := make([]map[string]string, 0)

	for rows.Next() {
		var eventUniqueKey string
		var creatorId string
		var toUserId string
		var groupId string
		var eventHeader string
		var eventTitle string
		var eventDescription string
		var place string
		var eventType string
		var date string
		var time string
		err = rows.Scan(&eventUniqueKey, &creatorId, &toUserId, &groupId, &eventHeader, &eventTitle, &eventDescription, &place, &eventType, &date, &time)
		if err != nil {
			return nil, err
		}
		event := make(map[string]string)
		event["eventUniqueKey"] = eventUniqueKey
		event["creatorId"] = creatorId
		event["toUserId"] = toUserId
		event["groupId"] = groupId
		event["eventHeader"] = eventHeader
		event["eventTitle"] = eventTitle
		event["eventDescription"] = eventDescription
		event["place"] = place
		event["eventType"] = eventType
		event["date"] = date
		event["time"] = time

		events = append(events, event)
	}

	response := make(map[string][]map[string]string)
	response["events"] = events

	return response, nil
}

func (m *EventManager) getEvent(params GetEventParams) (map[string]string, error) {
	if !isUserValid(params.UserId, m.connectionPool.db) {
		return nil, errors.New("can't search new groups. user not valid")
	}

	getQuery := `select e.event_key,
						e.creator_user_id,
						coalesce(e.to_user_id, '') user_id,
						coalesce(e.group_id, '') group_id,
						(case when e.to_user_id is null
						then (select group_title
							from groups g
							where g.group_id = e.group_id)
						when e.to_user_id = $2 then 
						(select u.first_name || ' ' || u.last_name
								from users u
							where u.user_id = e.creator_user_id)
						else (select u.first_name || ' ' || u.last_name
								from users u
							where u.user_id = e.to_user_id) end) event_header,
						e.event_title,
						coalesce(e.event_description, '') eventDescription,
						e.event_place,
						e.event_type,
						e.event_date,
						coalesce(e.event_time, '-:-') event_time
				from events e
				where e.event_key = $1;`

	var eventUniqueKey string
	var creatorId string
	var toUserId string
	var groupId string
	var eventHeader string
	var eventTitle string
	var eventDescription string
	var place string
	var eventType string
	var date string
	var time string

	if err := m.connectionPool.db.QueryRow(getQuery, params.EventUniqueKey, params.UserId).Scan(&eventUniqueKey, &creatorId, &toUserId, &groupId, &eventHeader, &eventTitle, &eventDescription, &place, &eventType, &date, &time); err != nil {
		return nil, err
	}

	response := make(map[string]string)
	response["eventUniqueKey"] = eventUniqueKey
	response["creatorId"] = creatorId
	response["toUserId"] = toUserId
	response["groupId"] = groupId
	response["eventHeader"] = eventHeader
	response["eventTitle"] = eventTitle
	response["eventDescription"] = eventDescription
	response["place"] = place
	response["eventType"] = eventType
	response["date"] = date
	response["time"] = time

	return response, nil
}

func (m *EventManager) createNewEvent(params CreateNewEventParams) error {
	if !isUserValid(params.UserId, m.connectionPool.db) {
		return errors.New("can't search new groups. user not valid")
	}

	insertQuery := `insert into events(creator_user_id, group_id, event_title, event_place, 
									event_type, event_description, event_date, event_time, formatted_date, event_key)
					values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);`

	_, err := m.connectionPool.db.Exec(insertQuery, params.UserId, params.GroupId, params.EventName, params.Place, "in_group",
		params.EventDescription, params.Date, params.Time, params.FormattedDate, params.EventUniqueKey)
	if err != nil {
		return err
	}

	return nil
}
