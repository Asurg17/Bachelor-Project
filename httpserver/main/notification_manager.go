package main

import (
	"database/sql"
	"errors"
)

type NotificationManager struct {
	connectionPool *PGConnectionPool
}

func NewNotificationManager(connectionPool *PGConnectionPool) *NotificationManager {
	notificationManager := new(NotificationManager)
	notificationManager.connectionPool = connectionPool
	return notificationManager
}

// Manager Functions

func (m *NotificationManager) getUserNotifications(userId string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get notifications. user not valid")
	}

	getQuery := `select r.id request_unique_id
					,s.user_id from_user_id
					,s.first_name || ' ' || s.last_name whole_name
					,true is_friendship_request
					,'' group_id
					,'' group_title
					,'' group_description
					,0 group_capacity
					,0 members_count
					,r.request_date
				from friendship_requests r,
				users s
				where s.user_id = from_user_id
				and r.to_user_id = $1
				and r.status = 'N'
				UNION ALL
				select s.id request_unique_id
					,u.user_id from_user_id
					,u.first_name || ' ' || u.last_name whole_name
					,false is_friendship_request
					,g.group_id
					,g.group_title
					,g.group_description
					,g.group_capacity
					,(select count(*)
					from group_members 
					where group_id = g.group_id) members_count
					,s.invitation_date
				from invitations s,
				groups g,
				users u
				where s.to_user_id = $1
				and s.status = 'N'
				and g.group_id = s.group_id
				and u.user_id = s.from_user_id
				and not exists (select *
							from group_members m
							where m.group_id = g.group_id
							and m.user_id = s.to_user_id)
				order by 10 desc;`

	rows, err := m.connectionPool.db.Query(getQuery, userId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	notifications := make([]map[string]string, 0)

	for rows.Next() {
		var requestUniqueKey string
		var fromUserId string
		var fromUserWholeName string
		var isFriendshipRequest string
		var groupId string
		var groupTitle string
		var groupDescription string
		var groupCapacity string
		var membersCount string
		var sendDate string
		err = rows.Scan(&requestUniqueKey, &fromUserId, &fromUserWholeName, &isFriendshipRequest,
			&groupId, &groupTitle, &groupDescription, &groupCapacity, &membersCount, &sendDate)
		if err != nil {
			return nil, err
		}
		notification := make(map[string]string)
		notification["requestUniqueKey"] = requestUniqueKey
		notification["fromUserId"] = fromUserId
		notification["fromUserWholeName"] = fromUserWholeName
		notification["isFriendshipRequest"] = isFriendshipRequest
		notification["groupId"] = groupId
		notification["groupTitle"] = groupTitle
		notification["groupDescription"] = groupDescription
		notification["groupCapacity"] = groupCapacity
		notification["membersCount"] = membersCount

		notifications = append(notifications, notification)
	}

	response := make(map[string][]map[string]string)
	response["notifications"] = notifications

	return response, nil
}

func (m *NotificationManager) sendGroupInvitations(userId string, groupId string, addSelfToGroup string, members []string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't send group invitations. user not valid")
	}

	if addSelfToGroup == "Y" {
		query := `insert into group_members ("group_id", "user_id", "user_role") 
					values ($1, $2, $3)`
		_, err := m.connectionPool.db.Exec(query, groupId, userId, "A")
		if err != nil {
			return err
		}
	}

	for _, groupMemberId := range members {
		query := `insert into invitations ("from_user_id", "to_user_id", "group_id") 
					values ($1, $2, $3)`
		_, err := m.connectionPool.db.Exec(query, userId, groupMemberId, groupId)
		if err != nil {
			return err
		}
	}

	return nil
}

func (m *NotificationManager) sendFriendshipRequest(fromUserId string, toUserId string) error {
	if !isUserValid(fromUserId, m.connectionPool.db) || !isUserValid(toUserId, m.connectionPool.db) {
		return errors.New("can't send friendship request. user not valid")
	}

	insertQuery := `insert into friendship_requests(from_user_id, to_user_id) 
					values ($1, $2);`

	_, err := m.connectionPool.db.Exec(insertQuery, fromUserId, toUserId)
	if err != nil {
		return err
	}

	return nil
}

func (m *NotificationManager) acceptFriendshipRequest(fromUserId string, toUserId string, requestUniqueKey string) error {
	if !isUserValid(fromUserId, m.connectionPool.db) || !isUserValid(toUserId, m.connectionPool.db) {
		return errors.New("can't accept friendship request. user not valid")
	}

	query := `create or replace procedure acceptFriendship(requestUniqueKey integer
																,fromUserId character varying
																,toUserId   character varying)
					language plpgsql
					as $$
					begin 
					update friendship_requests
					set status = 'A'
					where id = requestUniqueKey
					and to_user_id = toUserId
					and from_user_id = fromUserId;
					
					insert into friends (user_id, friend_id)
					values(toUserId, fromUserId);
	
					insert into friends (user_id, friend_id)
					values(fromUserId, toUserId);
					end;$$`

	_, err := m.connectionPool.db.Exec(query)
	if err != nil {
		return err
	}

	exequteQuery := `call acceptFriendship($1, $2, $3);`

	_, err = m.connectionPool.db.Exec(exequteQuery, requestUniqueKey, fromUserId, toUserId)
	if err != nil {
		return err
	}

	return nil
}

func (m *NotificationManager) rejectFriendshipRequest(fromUserId string, requestUniqueKey string) error {
	if !isUserValid(fromUserId, m.connectionPool.db) {
		return errors.New("can't reject friendship request. user not valid")
	}

	updateQuery := `update friendship_requests
					set status = 'R'
					where id = $1
					and to_user_id = $2;`

	_, err := m.connectionPool.db.Exec(updateQuery, requestUniqueKey, fromUserId)
	if err != nil {
		return err
	}

	return nil
}

func (m *NotificationManager) acceptInvitation(fromUserId string, toUserId string, groupId string, requestUniqueKey string) error {
	if !isUserValid(fromUserId, m.connectionPool.db) || !isUserValid(toUserId, m.connectionPool.db) {
		return errors.New("can't accept group invitation. user not valid")
	}

	query := `create or replace procedure acceptInvitation(requestUniqueKey integer
															,groupId        character varying
															,fromUserId     character varying
															,toUserId       character varying)
					language plpgsql
					as $$
					begin 
					update invitations
					set status = 'A'
					where id = requestUniqueKey
					and to_user_id = toUserId
					and from_user_id = fromUserId;
					
					insert into group_members (group_id, user_id)
					values (groupId, toUserId);
					end;$$`

	_, err := m.connectionPool.db.Exec(query)
	if err != nil {
		return err
	}

	insertQuery := `call acceptInvitation($1, $2, $3, $4);`

	_, err = m.connectionPool.db.Exec(insertQuery, requestUniqueKey, groupId, fromUserId, toUserId)
	if err != nil {
		return err
	}

	return nil
}

func (m *NotificationManager) rejectInvitation(toUserId string, requestUniqueKey string) error {
	if !isUserValid(toUserId, m.connectionPool.db) {
		return errors.New("can't reject group invitation. user not valid")
	}

	updateQuery := `update invitations
					set status = 'R'
					where id = $1
					and to_user_id = $2;`

	_, err := m.connectionPool.db.Exec(updateQuery, requestUniqueKey, toUserId)
	if err != nil {
		return err
	}

	return nil
}
