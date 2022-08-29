package main

import (
	"database/sql"
	"errors"
	"strings"
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

	getQuery := `select n.id request_unique_id
					,n.from_user_id from_user_id
					,us.first_name || ' ' || us.last_name notification_title
					,n.notification_text || coalesce(g.group_title, '') notification_text
					,n.notification_type
					,coalesce(g.group_id, '') group_id
					,coalesce(g.group_title, '') group_title
					,coalesce(g.group_description, '') group_description
					,coalesce(g.group_capacity, 0) group_capacity
					,(select count(*)
					from group_members 
					where group_id = g.group_id) members_count
					,to_char(n.inp_date, 'DD-FMMonth-YYYY') send_date
					,to_char(n.inp_date, 'HH24:MI') send_time
					,n.inp_date dt
				from notifications n
				join users us on us.user_id = n.from_user_id
				left join groups g on g.group_id = n.group_id
				where n.to_user_id = $1
				and n.notification_status = 'A'
				and us.user_id = n.from_user_id
				UNION ALL
				select r.id request_unique_id
					,s.user_id from_user_id
					,s.first_name || ' ' || s.last_name notification_title
					,'Sent you friendship request' notification_text
					,'friendship_request' notification_type
					,'' group_id
					,'' group_title
					,'' group_description
					,0 group_capacity
					,0 members_count
					,to_char(r.request_date, 'DD-FMMonth-YYYY') send_date
					,to_char(r.request_date, 'HH24:MI') send_time
					,r.request_date dt
				from friendship_requests r,
				users s
				where r.to_user_id = $1
				and r.status = 'N'
				and s.user_id = from_user_id
				UNION ALL
				select s.id request_unique_id
					,u.user_id from_user_id
					,u.first_name || ' ' || u.last_name notification_title
					,'Invited you to joing group: ' || g.group_title notification_text
					,'group_invitation' notification_type
					,g.group_id
					,g.group_title
					,g.group_description
					,g.group_capacity
					,(select count(*)
					from group_members 
					where group_id = g.group_id) members_count
					,to_char(s.invitation_date, 'DD-FMMonth-YYYY') send_date
					,to_char(s.invitation_date, 'HH24:MI') send_time
					,s.invitation_date dt
				from invitations s,
				groups g,
				users u
				where s.to_user_id = $1
				and s.status = 'N'
				and g.group_id = s.group_id
				and u.user_id = s.from_user_id
				and exists (select *
						from friends f
						where f.user_id = $1
						and f.friend_id = s.from_user_id)
				and not exists (select *
						from group_members m
						where m.group_id = g.group_id
						and m.user_id = s.to_user_id)
				order by 13 desc;`

	rows, err := m.connectionPool.db.Query(getQuery, userId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	notifications := make([]map[string]string, 0)

	for rows.Next() {
		var requestUniqueKey string
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
		err = rows.Scan(&requestUniqueKey, &fromUserId, &notificationTitle, &notificationText, &notificationType, &groupId, &groupTitle, &groupDescription, &groupCapacity, &membersCount, &sendDate, &sendTime, &dt)
		if err != nil {
			return nil, err
		}
		notification := make(map[string]string)
		notification["requestUniqueKey"] = requestUniqueKey
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

func (m *NotificationManager) sendGroupInvitations(userId string, groupId string, members []string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't send group invitations. user not valid")
	}

	if !isUserGroupMember(userId, groupId, m.connectionPool.db) {
		return errors.New("you have been removed from this group")
	}

	for _, groupMemberId := range members {
		query := `insert into invitations ("from_user_id", "to_user_id", "group_id") 
					select  CAST($1 AS VARCHAR), CAST($2 AS VARCHAR), CAST($3 AS VARCHAR)
					where not exists (select *
									from invitations i
									where i.to_user_id = $2
									and i.group_id = $3
									and i.status = 'N')
					and exists (select *
								from friends s
								where s.user_id = $1
								and s.friend_id = $2);`
		_, err := m.connectionPool.db.Exec(query, userId, groupMemberId, groupId)
		if err != nil && !strings.Contains(err.Error(), "invitations_uk") { //invitations_uk means someone already has sent invitations to user
			return err
		}
	}

	return nil
}

func (m *NotificationManager) sendFriendshipRequest(fromUserId string, toUserId string, groupId string) error {
	if !isUserValid(fromUserId, m.connectionPool.db) || !isUserValid(toUserId, m.connectionPool.db) {
		return errors.New("can't send friendship request. user not valid")
	}

	if !isUserGroupMember(fromUserId, groupId, m.connectionPool.db) {
		return errors.New("you have been removed from this group")
	}

	insertQuery := `insert into friendship_requests(from_user_id, to_user_id) 
					select CAST($1 AS VARCHAR), CAST($2 AS VARCHAR)
					where exists (select s.user_id
								from group_members s
								where s.user_id = $1
								and s.group_id = $3);`

	_, err := m.connectionPool.db.Exec(insertQuery, fromUserId, toUserId, groupId)
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
				update invitations
				set status = 'A'
				where status = 'N'
				and to_user_id = toUserId
				and group_id = groupId;
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
