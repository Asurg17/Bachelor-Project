package main

import (
	"database/sql"
	"errors"
)

type MessageManager struct {
	connectionPool *PGConnectionPool
}

func NewMessageManager(connectionPool *PGConnectionPool) *MessageManager {
	messageManager := new(MessageManager)
	messageManager.connectionPool = connectionPool
	return messageManager
}

// Manager Functions

func (m *MessageManager) sendMessage(messageId string, messageType string, senderId string, groupId string, content string, sendDate string, sendDateTimestamp string, duration string) error {
	if !isUserValid(senderId, m.connectionPool.db) {
		return errors.New("can't send message. user not valid")
	}

	query := `insert into messages(message_id, type, sender_id, group_id, content, send_date, send_date_timestamp, duration)
				values ($1, $2, $3, $4, $5, $6, $7, $8);`

	_, err := m.connectionPool.db.Exec(query, messageId, messageType, senderId, groupId, content, sendDate, sendDateTimestamp, duration)
	if err != nil {
		return err
	}

	return nil
}

func (m *MessageManager) getAllGroupMessages(userId string, groupId string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get group messages. user not valid")
	}

	getQuery := `select m.sender_id,
						(select s.first_name
						from users s
						where s.user_id = m.sender_id) name,
						m.message_id,
						m.send_date,
						m.type,
						m.content,
						m.send_date_timestamp,
						m.duration
					from messages m
					where m.group_id = $1
					order by m.send_date_timestamp;`

	rows, err := m.connectionPool.db.Query(getQuery, groupId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	messages := make([]map[string]string, 0)

	for rows.Next() {
		var senderId string
		var senderName string
		var messageId string
		var sentDate string
		var messageType string
		var content string
		var sendDateTimestamp string
		var duration string
		err = rows.Scan(&senderId, &senderName, &messageId, &sentDate, &messageType, &content, &sendDateTimestamp, &duration)
		if err != nil {
			return nil, err
		}
		message := make(map[string]string)
		message["senderId"] = senderId
		message["senderName"] = senderName
		message["messageId"] = messageId
		message["sentDate"] = sentDate
		message["messageType"] = messageType
		message["content"] = content
		message["sendDateTimestamp"] = sendDateTimestamp
		message["duration"] = duration

		messages = append(messages, message)
	}

	response := make(map[string][]map[string]string)
	response["messages"] = messages

	return response, nil
}

func (m *MessageManager) getNewMessages(userId string, groupId string, lastMessageSentDateTimestamp string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get messages. user not valid")
	}

	getQuery := `select m.sender_id,
						(select s.first_name
						from users s
						where s.user_id = m.sender_id) name,
						m.message_id,
						m.send_date,
						m.type,
						m.content,
						m.send_date_timestamp,
						m.duration
					from messages m
					where m.group_id = $1
					and m.send_date_timestamp > $2
					order by m.send_date_timestamp;`

	rows, err := m.connectionPool.db.Query(getQuery, groupId, lastMessageSentDateTimestamp)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	messages := make([]map[string]string, 0)

	for rows.Next() {
		var senderId string
		var senderName string
		var messageId string
		var sentDate string
		var messageType string
		var content string
		var sendDateTimestamp string
		var duration string
		err = rows.Scan(&senderId, &senderName, &messageId, &sentDate, &messageType, &content, &sendDateTimestamp, &duration)
		if err != nil {
			return nil, err
		}
		message := make(map[string]string)
		message["senderId"] = senderId
		message["senderName"] = senderName
		message["messageId"] = messageId
		message["sentDate"] = sentDate
		message["messageType"] = messageType
		message["content"] = content
		message["sendDateTimestamp"] = sendDateTimestamp
		message["duration"] = duration

		messages = append(messages, message)
	}

	response := make(map[string][]map[string]string)
	response["messages"] = messages

	return response, nil
}
