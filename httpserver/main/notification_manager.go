package main

import (
	"database/sql"
	"errors"

	"github.com/gorilla/websocket"
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

func (m *NotificationManager) updateNotificationsLastFetchTime(userId string) error {
	var alreadyExists bool

	getQuery := `select true
				from last_notification_fetch_time t
				where t.user_id = $1;`

	if err := m.connectionPool.db.QueryRow(getQuery, userId).Scan(&alreadyExists); err != nil {
		if err == sql.ErrNoRows {
			alreadyExists = false
		} else {
			return err
		}
	}

	if alreadyExists {
		updateQuery := `update last_notification_fetch_time
						set fetch_time = now()
						where user_id = $1;`

		_, err := m.connectionPool.db.Exec(updateQuery, userId)
		if err != nil {
			return err
		}
	} else {
		insertQuery := `insert into last_notification_fetch_time(user_id)
						values($1);`

		_, err := m.connectionPool.db.Exec(insertQuery, userId)
		if err != nil {
			return err
		}
	}

	return nil
}

func (m *NotificationManager) notifyGroupMembers(fromUserId string, text string, groupId string) error {
	getQuery := `select m.user_id
				from group_members m
				where m.group_id = $1;`

	rows, err := m.connectionPool.db.Query(getQuery, groupId)
	if err != nil && err != sql.ErrNoRows {
		return err
	}
	defer rows.Close()

	insertQuery := `insert into notifications(from_user_id, to_user_id, notification_text, group_id)
						values ($1, $2, $3, $4);`

	for rows.Next() {
		var userId string
		err = rows.Scan(&userId)
		if err != nil {
			return err
		}

		if userId != fromUserId {
			_, err := m.connectionPool.db.Exec(insertQuery, fromUserId, userId, text, groupId)
			if err != nil {
			return err
			}

			mainConnectionsMutex.Lock()
			if conn, found := mainConnections[userId]; found {
				if err := conn.WriteMessage(websocket.BinaryMessage, []byte("new notification")); err != nil {
					msgConnectionsMutex.Unlock()
					return err
				}
			}
			mainConnectionsMutex.Unlock()
		}
	}

	return nil
}

func (m *NotificationManager) notifyUserAboutNewNotification(userId string) error {
	mainConnectionsMutex.Lock()
	if conn, found := mainConnections[userId]; found {
		if err := conn.WriteMessage(websocket.BinaryMessage, []byte("new notification")); err != nil {
			msgConnectionsMutex.Unlock()
			return err
		}
	}
	mainConnectionsMutex.Unlock()

	return nil
}

func (m *NotificationManager) checkForNewNotifications(userId string, lastSeenNotificationUniqueKey string) (map[string]string, error) {
	var lastFetchTime string
	var newNotificationsNum string

	getQuery := `select count(*)
				from notifications n
				where n.to_user_id = $1
				and n.from_user_id != $1
				and((n.type = 'default')
					or
					(n.status = 'N'
				    and n.type = 'friendship_request')
					or
					(n.status = 'N'
					and n.type = 'group_invitation'
					and exists (select *
								from friends f
								where f.user_id = n.to_user_id
								and f.friend_id = n.from_user_id)
					and not exists (select *
									from group_members m
									where m.group_id = coalesce(n.group_id, '')
									and m.user_id = n.to_user_id)))
				and n.id > $2;`
	
	param := lastSeenNotificationUniqueKey

	if lastSeenNotificationUniqueKey == "-1" {
		query := `select to_char(fetch_time, 'YYYY-MM-DD HH24:MI:SS:MS')
					from last_notification_fetch_time
					where user_id = $1;`

		if err := m.connectionPool.db.QueryRow(query, userId).Scan(&lastFetchTime); err != nil {
			if err != sql.ErrNoRows {
				return nil, err
			}
		}	

		if len(lastFetchTime) > 0 {
			print(lastFetchTime)
		
			getQuery = `select count(*)
						from notifications n
						where n.to_user_id = $1
						and((n.type = 'default')
							or
							(n.status = 'N'
							and n.type = 'friendship_request')
							or
							(n.status = 'N'
							and n.type = 'group_invitation'
							and exists (select *
										from friends f
										where f.user_id = n.to_user_id
										and f.friend_id = n.from_user_id)
							and not exists (select *
											from group_members m
											where m.group_id = coalesce(n.group_id, '')
											and m.user_id = n.to_user_id)))
						and to_char(n.inp_date, 'YYYY-MM-DD HH24:MI:SS:MS') > $2;`
			
			param = lastFetchTime
		}
	}
	

	if e := m.connectionPool.db.QueryRow(getQuery, userId, param).Scan(&newNotificationsNum); e != nil {
		if e == sql.ErrNoRows {
			newNotificationsNum = "0"
		} else {
			return nil, e
		}
	}

	response := make(map[string]string)
	response["newNotificationsNum"] = newNotificationsNum

	return response, nil
}

func (m *NotificationManager) getUserNotifications(userId string, lastNotificationUniqueKey string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get notifications. user not valid")
	}

	err := m.updateNotificationsLastFetchTime(userId)
	if err != nil {
		return nil, err
	}

	getQuery := `select n.id notification_unique_key
					,n.from_user_id from_user_id
					,us.first_name || ' ' || us.last_name notification_title
					,n.notification_text || coalesce(g.group_title, '') notification_text
					,n.type notification_type
					,coalesce(g.group_id, '') group_id
					,coalesce(g.group_title, '') group_title
					,coalesce(g.group_description, '') group_description
					,coalesce(g.group_capacity, 0) group_capacity
					,(select count(*)
					from group_members 
					where group_id = g.group_id) members_count
					,to_char(n.inp_date, 'DD FMMonth YYYY') send_date
					,to_char(n.inp_date, 'HH24:MI') send_time
					,n.inp_date dt
				from notifications n
				join users us on us.user_id = n.from_user_id
				left join groups g on g.group_id = n.group_id
				where n.to_user_id = $1
				and n.from_user_id != $1
				and n.notification_status = 'A'
				and us.user_id = n.from_user_id
				and n.type = 'default'
				and n.id > $2
				UNION ALL
				select r.id notification_unique_key
					,s.user_id from_user_id
					,s.first_name || ' ' || s.last_name notification_title
					,'Sent you friendship request' notification_text
					,r.type notification_type
					,'' group_id
					,'' group_title
					,'' group_description
					,0 group_capacity
					,0 members_count
					,to_char(r.inp_date, 'DD FMMonth YYYY') send_date
					,to_char(r.inp_date, 'HH24:MI') send_time
					,r.inp_date dt
				from notifications r,
				users s
				where r.to_user_id = $1
				and r.status = 'N'
				and s.user_id = from_user_id
				and r.type = 'friendship_request'
				and r.id > $2
				UNION ALL
				select s.id notification_unique_key
					,u.user_id from_user_id
					,u.first_name || ' ' || u.last_name notification_title
					,'Invited you to joing group: ' || g.group_title notification_text
					,s.type notification_type
					,g.group_id
					,g.group_title
					,g.group_description
					,g.group_capacity
					,(select count(*)
					from group_members 
					where group_id = g.group_id) members_count
					,to_char(s.inp_date, 'DD FMMonth YYYY') send_date
					,to_char(s.inp_date, 'HH24:MI') send_time
					,s.inp_date dt
				from notifications s,
				groups g,
				users u
				where s.to_user_id = $1
				and s.status = 'N'
				and g.group_id = s.group_id
				and u.user_id = s.from_user_id
				and s.type = 'group_invitation'
				and s.id > $2
				and exists (select *
						from friends f
						where f.user_id = $1
						and f.friend_id = s.from_user_id)
				and not exists (select *
						from group_members m
						where m.group_id = g.group_id
						and m.user_id = s.to_user_id)
				order by 13 desc;`

	rows, err := m.connectionPool.db.Query(getQuery, userId, lastNotificationUniqueKey)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	notifications := make([]map[string]string, 0)

	for rows.Next() {
		var notificationUniqueKey string
		var fromUserId string
		var notificationTitle string
		var notificationText string
		var notificationType string
		var groupId string
		var groupTitle string
		var groupDescription string
		var groupCapacity string
		var membersCount string
		var sendDate string
		var sendTime string
		var dt string
		err = rows.Scan(&notificationUniqueKey, &fromUserId, &notificationTitle, &notificationText, &notificationType, &groupId, &groupTitle, &groupDescription, &groupCapacity, &membersCount, &sendDate, &sendTime, &dt)
		if err != nil {
			return nil, err
		}
		notification := make(map[string]string)
		notification["notificationUniqueKey"] = notificationUniqueKey
		notification["fromUserId"] = fromUserId
		notification["notificationTitle"] = notificationTitle
		notification["notificationText"] = notificationText
		notification["notificationType"] = notificationType
		notification["groupId"] = groupId
		notification["groupTitle"] = groupTitle
		notification["groupDescription"] = groupDescription
		notification["groupCapacity"] = groupCapacity
		notification["membersCount"] = membersCount
		notification["sendDate"] = sendDate
		notification["sendTime"] = sendTime

		notifications = append(notifications, notification)
	}

	response := make(map[string][]map[string]string)
	response["notifications"] = notifications

	return response, nil
}

func (m *NotificationManager) sendFriendshipRequest(fromUserId string, toUserId string, groupId string) error {
	if !isUserValid(fromUserId, m.connectionPool.db) || !isUserValid(toUserId, m.connectionPool.db) {
		return errors.New("can't send friendship request. user not valid")
	}

	if !isUserGroupMember(fromUserId, groupId, m.connectionPool.db) {
		return errors.New("you have been removed from this group")
	}

	insertQuery := `insert into notifications(from_user_id, to_user_id, type)
					select CAST($1 AS VARCHAR), CAST($2 AS VARCHAR), 'friendship_request'
					where exists (select s.user_id
								from group_members s
								where s.user_id = $1
								and s.group_id = $3);`

	// insertQuery := `insert into friendship_requests(from_user_id, to_user_id) 
	// 				select CAST($1 AS VARCHAR), CAST($2 AS VARCHAR)
	// 				where exists (select s.user_id
	// 							from group_members s
	// 							where s.user_id = $1
	// 							and s.group_id = $3);`

	_, err := m.connectionPool.db.Exec(insertQuery, fromUserId, toUserId, groupId)
	if err != nil {
		return err
	}

	err = m.notifyUserAboutNewNotification(toUserId)
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
					update notifications
					set status = 'A'
					where id = requestUniqueKey
					and to_user_id = toUserId
					and from_user_id = fromUserId
					and type = 'friendship_request';
					
					insert into friends (user_id, friend_id)
					values(toUserId, fromUserId);
	
					insert into friends (user_id, friend_id)
					values(fromUserId, toUserId);

					insert into notifications(from_user_id, to_user_id, notification_text)
					values (toUserId, fromUserId, 'Accepted your friendship request');

					commit;
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

	err = m.notifyUserAboutNewNotification(fromUserId)
	if err != nil {
		return err
	}

	return nil
}

func (m *NotificationManager) rejectFriendshipRequest(fromUserId string, requestUniqueKey string) error {
	if !isUserValid(fromUserId, m.connectionPool.db) {
		return errors.New("can't reject friendship request. user not valid")
	}

	updateQuery := `update notifications
					set status = 'R'
					where id = $1
					and to_user_id = $2
					and type = 'friendship_request';`

	_, err := m.connectionPool.db.Exec(updateQuery, requestUniqueKey, fromUserId)
	if err != nil {
		return err
	}

	return nil
}

func (m *NotificationManager) sendGroupInvitations(userId string, groupId string, members []string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't send group invitations. user not valid")
	}

	if !isUserGroupMember(userId, groupId, m.connectionPool.db) {
		return errors.New("you have been removed from this group")
	}

	for _, groupMemberId := range members {
		query := `insert into notifications (from_user_id, to_user_id, group_id, type) 
					select  CAST($1 AS VARCHAR), CAST($2 AS VARCHAR), CAST($3 AS VARCHAR), 'group_invitation'
					where exists (select s.user_id
									from group_members s
									where s.user_id = $1
									and s.group_id = $3)
					and not exists (select *
									from notifications n
									where n.to_user_id = $2
									and n.group_id = $3
									and n.status = 'N'
									and n.type = 'group_invitation')
					and exists (select *
								from friends s
								where s.user_id = $1
								and s.friend_id = $2);`

		// query := `insert into invitations ("from_user_id", "to_user_id", "group_id") 
		// 			select  CAST($1 AS VARCHAR), CAST($2 AS VARCHAR), CAST($3 AS VARCHAR)
		// 			where not exists (select *
		// 							from invitations i
		// 							where i.to_user_id = $2
		// 							and i.group_id = $3
		// 							and i.status = 'N')
		// 			and exists (select *
		// 						from friends s
		// 						where s.user_id = $1
		// 						and s.friend_id = $2);`
		_, err := m.connectionPool.db.Exec(query, userId, groupMemberId, groupId)
		if err != nil { //invitations_uk means someone already has sent invitations to user
			return err
		}

		err = m.notifyUserAboutNewNotification(groupMemberId)
		if err != nil {
			return err
		}
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
				--
				insert into group_members (group_id, user_id)
				select groupId, toUserId
				where not exists (select *
					from group_members m
					where m.group_id = groupId
					and m.user_id = toUserId);
				--
				insert into notifications(from_user_id, to_user_id, notification_text, group_id)
				values (toUserId, fromUserId, 'Accepted your invitation to ', groupId);
				--
				update notifications
				set status = 'A'
				where status = 'N'
				and to_user_id = toUserId
				and group_id = groupId
				and type = 'group_invitation';
				--
				commit;
				--
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

	err = m.notifyUserAboutNewNotification(fromUserId)
	if err != nil {
		return err
	}

	return nil
}

func (m *NotificationManager) rejectInvitation(toUserId string, requestUniqueKey string) error {
	if !isUserValid(toUserId, m.connectionPool.db) {
		return errors.New("can't reject group invitation. user not valid")
	}

	updateQuery := `update notifications
					set status = 'R'
					where id = $1
					and to_user_id = $2
					and type = 'group_invitation';`

	_, err := m.connectionPool.db.Exec(updateQuery, requestUniqueKey, toUserId)
	if err != nil {
		return err
	}

	return nil
}

func (m *NotificationManager) createNewNotification(userId string, toUserId string, text string, groupId string) error {
	if len(groupId) > 0 {
		err := m.notifyGroupMembers(userId, text, groupId)
		if err != nil {
			return err
		}
	} else {
		insertQuery := `insert into notifications(from_user_id, to_user_id, notification_text)
						values ($1, $2, $3);`

		_, err := m.connectionPool.db.Exec(insertQuery, userId, toUserId, text)
		if err != nil {
		return err
		}

		err = m.notifyUserAboutNewNotification(toUserId)
		if err != nil {
			return err
		}
	}

	return nil
}
