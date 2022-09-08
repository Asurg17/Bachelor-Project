package main

import (
	"database/sql"
	"errors"
)

type TaskManager struct {
	connectionPool *PGConnectionPool
}

func NewTaskManager(connectionPool *PGConnectionPool) *TaskManager {
	taskManager := new(TaskManager)
	taskManager.connectionPool = connectionPool
	return taskManager
}

// Manager Functions

func (m *TaskManager) getEventTasks(userId string, eventKey string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't search new groups. user not valid")
	}

	getQuery := `select t.user_id,
						(select u.first_name || ' ' || u.last_name
						from users u
						where u.user_id = t.user_id) name,
						t.event_key,
						t.task,
						e.event_date,
						coalesce(e.event_time, '-:-'),
						t.id,
						t.status
				from events e,
					tasks t
				where e.event_key = $1
				and t.event_key = e.event_key
				order by (case when t.user_id = $2 then 1
						else 2 end),
					t.inp_date desc;`

	rows, err := m.connectionPool.db.Query(getQuery, eventKey, userId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	tasks := make([]map[string]string, 0)

	for rows.Next() {
		var assigneeId string
		var assigneeName string
		var eventKey string
		var taskTitle string
		var date string
		var time string
		var taskId string
		var taskStatus string
		err = rows.Scan(&assigneeId, &assigneeName, &eventKey, &taskTitle, &date, &time, &taskId, &taskStatus)
		if err != nil {
			return nil, err
		}
		task := make(map[string]string)
		task["assigneeId"] = assigneeId
		task["assigneeName"] = assigneeName
		task["eventKey"] = eventKey
		task["taskTitle"] = taskTitle
		task["date"] = date
		task["time"] = time
		task["taskId"] = taskId
		task["taskStatus"] = taskStatus

		tasks = append(tasks, task)
	}

	response := make(map[string][]map[string]string)
	response["tasks"] = tasks

	return response, nil
}

func (m *TaskManager) getUserTasks(userId string, currentDate string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't search new groups. user not valid")
	}

	getQuery := `select t.user_id,
						'Event: ' || e.event_title name,
						t.event_key,
						t.task,
						e.event_date,
						coalesce(e.event_time, '-:-'),
						t.id,
						t.status
				from tasks t,
				events e
				where t.user_id = $1
				and e.event_key = t.event_key
				and e.formatted_date >= $2
				and (case when e.group_id is not null
						then exists(select *
							from group_members m
							where m.group_id = e.group_id
							and m.user_id = t.user_id) else false end)
				order by e.formatted_date,
					(case when e.event_time = '-:-' then 2 else 1 end),
					e.event_time,
					t.inp_date desc;`

	rows, err := m.connectionPool.db.Query(getQuery, userId, currentDate)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	tasks := make([]map[string]string, 0)

	for rows.Next() {
		var assigneeId string
		var assigneeName string
		var eventKey string
		var taskTitle string
		var date string
		var time string
		var taskId string
		var taskStatus string
		err = rows.Scan(&assigneeId, &assigneeName, &eventKey, &taskTitle, &date, &time, &taskId, &taskStatus)
		if err != nil {
			return nil, err
		}
		task := make(map[string]string)
		task["assigneeId"] = assigneeId
		task["assigneeName"] = assigneeName
		task["eventKey"] = eventKey
		task["taskTitle"] = taskTitle
		task["date"] = date
		task["time"] = time
		task["taskId"] = taskId
		task["taskStatus"] = taskStatus

		tasks = append(tasks, task)
	}

	response := make(map[string][]map[string]string)
	response["tasks"] = tasks

	return response, nil
}

func (m *TaskManager) createNewTask(userId string, assigneeId string, task string, eventUniqueKey string) error {
	if !isUserValid(userId, m.connectionPool.db) || !isUserValid(assigneeId, m.connectionPool.db) {
		return errors.New("can't search new groups. user not valid")
	}

	insertQuery := `insert into tasks(user_id, event_key, task)
					values ($1, $2, $3);`

	_, err := m.connectionPool.db.Exec(insertQuery, assigneeId, eventUniqueKey, task)
	if err != nil {
		return err
	}

	return nil
}

func (m *TaskManager) doneTask(userId string, taskId string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't search new groups. user not valid")
	}

	updateQuery := `update tasks set status = 'D'
					where id = $1
					and user_id = $2;`

	_, err := m.connectionPool.db.Exec(updateQuery, taskId, userId)
	if err != nil {
		return err
	}

	return nil
}
