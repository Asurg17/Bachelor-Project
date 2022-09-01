package main

import (
	"database/sql"
	"errors"

	"github.com/gorilla/websocket"
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

func (m *MessageManager) notifyGroupMembers(messageId string, groupId string) error {
	getQuery := `select m.user_id
				from group_members m
				where m.group_id = $1;`

	rows, err := m.connectionPool.db.Query(getQuery, groupId)
	if err != nil && err != sql.ErrNoRows {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var userId string
		err = rows.Scan(&userId)
		if err != nil {
			return err
		}

		msgConnectionsMutex.Lock()
		if conn, found := msgConnections[userId]; found {
			if err := conn.WriteMessage(websocket.TextMessage, []byte("messages updated")); err != nil {
				msgConnectionsMutex.Unlock()
				return err
			}
		}
		msgConnectionsMutex.Unlock()
	}

	return nil
}

func (m *MessageManager) sendMessage(messageId string, messageType string, senderId string, groupId string, content string, sendDate string, sendDateTimestamp string, duration string) error {
	if !isUserValid(senderId, m.connectionPool.db) {
		return errors.New("can't send message. user not valid")
	}

	if !isUserGroupMember(senderId, groupId, m.connectionPool.db) {
		return errors.New("you have been removed from this group")
	}

	query := `insert into messages(message_id, type, sender_id, group_id, content, send_date, send_date_timestamp, duration)
				select CAST($1 AS VARCHAR), CAST($2 AS VARCHAR), CAST($3 AS VARCHAR), CAST($4 AS VARCHAR),
					CAST($5 AS VARCHAR), CAST($6 AS VARCHAR), CAST($7 AS VARCHAR), CAST($8 AS VARCHAR)
				where exists (select s.user_id
							from group_members s
							where s.user_id = $3
							and s.group_id = $4);`

	_, err := m.connectionPool.db.Exec(query, messageId, messageType, senderId, groupId, content, sendDate, sendDateTimestamp, duration)
	if err != nil {
		return err
	}

	err = m.notifyGroupMembers(messageId, groupId)
	if err != nil {
		return err
	}

	return nil
}

func (m *MessageManager) getAllGroupMessages(userId string, groupId string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get group messages. user not valid")
	}

	getQuery := `select m.* 
				from (select m.id,
						m.sender_id,
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
					order by m.id desc limit 30) m
					order by id;`

	rows, err := m.connectionPool.db.Query(getQuery, groupId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	messages := make([]map[string]string, 0)

	for rows.Next() {
		var messageUniqueKey string
		var senderId string
		var senderName string
		var messageId string
		var sentDate string
		var messageType string
		var content string
		var sendDateTimestamp string
		var duration string
		err = rows.Scan(&messageUniqueKey, &senderId, &senderName, &messageId, &sentDate, &messageType, &content, &sendDateTimestamp, &duration)
		if err != nil {
			return nil, err
		}
		message := make(map[string]string)
		message["messageUniqueKey"] = messageUniqueKey
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

func (m *MessageManager) getGroupNewMessages(userId string, groupId string, lastMessageUniqueKey string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get group messages. user not valid")
	}

	getQuery := `select m.id,
						m.sender_id,
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
					and m.id > $2
					order by m.id;`

	rows, err := m.connectionPool.db.Query(getQuery, groupId, lastMessageUniqueKey)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	messages := make([]map[string]string, 0)

	for rows.Next() {
		var messageUniqueKey string
		var senderId string
		var senderName string
		var messageId string
		var sentDate string
		var messageType string
		var content string
		var sendDateTimestamp string
		var duration string
		err = rows.Scan(&messageUniqueKey, &senderId, &senderName, &messageId, &sentDate, &messageType, &content, &sendDateTimestamp, &duration)
		if err != nil {
			return nil, err
		}
		message := make(map[string]string)
		message["messageUniqueKey"] = messageUniqueKey
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

func (m *MessageManager) getGroupOldMessages(userId string, groupId string, firstMessageUniqueKey string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get messages. user not valid")
	}

	getQuery := `select m.* 
				from (select m.id,
						m.sender_id,
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
					and m.id < $2
					order by m.id desc limit 30) m
					order by id;`

	rows, err := m.connectionPool.db.Query(getQuery, groupId, firstMessageUniqueKey)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	messages := make([]map[string]string, 0)

	for rows.Next() {
		var messageUniqueKey string
		var senderId string
		var senderName string
		var messageId string
		var sentDate string
		var messageType string
		var content string
		var sendDateTimestamp string
		var duration string
		err = rows.Scan(&messageUniqueKey, &senderId, &senderName, &messageId, &sentDate, &messageType, &content, &sendDateTimestamp, &duration)
		if err != nil {
			return nil, err
		}
		message := make(map[string]string)
		message["messageUniqueKey"] = messageUniqueKey
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
