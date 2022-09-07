package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
)

type UserManager struct {
	connectionPool *PGConnectionPool
}

func NewUserManager(connectionPool *PGConnectionPool) *UserManager {
	userManager := new(UserManager)
	userManager.connectionPool = connectionPool
	return userManager
}

// Manager Functions

func (m *UserManager) getUserInfo(userId string) (map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get user info. user not valid")
	}

	var username string
	var firstName string
	var lastName string
	var gender string
	var age string
	var location string
	var birthDate string
	var phone string

	getQuery := `select s.username, 
						s.first_name,
						coalesce(s.last_name, '-') last_name,
						coalesce(s.gender, '-') gender,
						coalesce(cast(s.age as varchar), '-') age,
						coalesce(s.location, '-') location,
						coalesce(s.birthdate, '-') birthdate,
						coalesce(s.phone, '-') phone
				from users s
				where s.user_id = $1;`

	if err := m.connectionPool.db.QueryRow(getQuery, userId).Scan(&username, &firstName, &lastName, &gender, &age, &location, &birthDate, &phone); err != nil {
		return nil, err
	}

	response := make(map[string]string)
	response["username"] = username
	response["firstName"] = firstName
	response["lastName"] = lastName
	response["gender"] = gender
	response["age"] = age
	response["location"] = location
	response["birthDate"] = birthDate
	response["phone"] = phone

	return response, nil
}

func (m *UserManager) getUserGroups(userId string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get user groups. user not valid")
	}

	getQuery := `select s.group_id
					   ,s.group_title
					   ,s.group_description
					   ,s.group_capacity
					   ,(select count(*)
					    from group_members 
						where group_id = m.group_id) members_count
					   ,m.user_role
					   ,(select count(*)
						from messages ms
						where ms.group_id = s.group_id
						and ms.id > coalesce((select coalesce(last_message_id, -1)
											from last_group_messages_fetch_time t
											where t.user_id = $1
											and t.group_id = ms.group_id), -1)) new_messages_count
				from groups s
					,group_members m
				where s.group_id = m.group_id
				and s.group_status = 'A'
				and m.user_id = $1
				order by m.inp_date desc;`

	rows, err := m.connectionPool.db.Query(getQuery, userId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	groups := make([]map[string]string, 0)

	for rows.Next() {
		var groupId string
		var groupTitle string
		var groupDescription string
		var groupCapacity string
		var groupMembersNum string
		var userRole string
		var newMessagesCount string
		err = rows.Scan(&groupId, &groupTitle, &groupDescription, &groupCapacity, &groupMembersNum, &userRole, &newMessagesCount)
		if err != nil {
			return nil, err
		}
		group := make(map[string]string)
		group["groupId"] = groupId
		group["groupTitle"] = groupTitle
		group["groupDescription"] = groupDescription
		group["groupCapacity"] = groupCapacity
		group["groupMembersNum"] = groupMembersNum
		group["userRole"] = userRole
		group["newMessagesCount"] = newMessagesCount

		groups = append(groups, group)
	}

	response := make(map[string][]map[string]string)
	response["groups"] = groups

	return response, nil
}

func (m *UserManager) getUserFriends(userId string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get user friends. user not valid")
	}

	getQuery := `select s.user_id
					,s.first_name
					,coalesce(s.last_name, '-') last_name
					,coalesce(s.phone, '-') phone
				from users s
				,friends f
				where f.user_id = $1
				and s.user_id = f.friend_id;`

	rows, err := m.connectionPool.db.Query(getQuery, userId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	friends := make([]map[string]string, 0)

	for rows.Next() {
		var friendId string
		var friendFirstName string
		var friendLastName string
		var friendPhone string
		err = rows.Scan(&friendId, &friendFirstName, &friendLastName, &friendPhone)
		if err != nil {
			return nil, err
		}
		friend := make(map[string]string)
		friend["friendId"] = friendId
		friend["friendFirstName"] = friendFirstName
		friend["friendLastName"] = friendLastName
		friend["friendPhone"] = friendPhone

		friends = append(friends, friend)
	}

	response := make(map[string][]map[string]string)
	response["friends"] = friends

	return response, nil
}

func (m *UserManager) searchNewFriends(userId string, firstName string, lastName string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get users. user not valid")
	}

	getQuery := `select s.user_id
					   ,s.first_name
						,coalesce(s.last_name, '-') last_name
						,coalesce(s.phone, '-') phone
				from users s
				where (lower(s.first_name) like lower('%' || $2 || '%'))
				and (lower(s.last_name) like lower('%' || $3 || '%'))
				and s.user_id != $1
				and not exists (select *
								from friends f
								where f.user_id = $1
								and f.friend_id = s.user_id)
			 	and not exists (select *
					   			from notifications r
								where ((r.from_user_id = $1 and r.to_user_id = s.user_id)
								   or (r.from_user_id = s.user_id and r.to_user_id = $1))
								and r.type = 'friendship_request'
								and r.status = 'N');`

	rows, err := m.connectionPool.db.Query(getQuery, userId, firstName, lastName)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	friends := make([]map[string]string, 0)

	for rows.Next() {
		var friendId string
		var friendFirstName string
		var friendLastName string
		var friendPhone string
		err = rows.Scan(&friendId, &friendFirstName, &friendLastName, &friendPhone)
		if err != nil {
			return nil, err
		}
		friend := make(map[string]string)
		friend["friendId"] = friendId
		friend["friendFirstName"] = friendFirstName
		friend["friendLastName"] = friendLastName
		friend["friendPhone"] = friendPhone

		friends = append(friends, friend)
	}

	response := make(map[string][]map[string]string)
	response["friends"] = friends

	return response, nil
}

func (m *UserManager) sendFriendshipRequestToUser(fromUserId string, toUSerId string) error {
	if !isUserValid(fromUserId, m.connectionPool.db) || !isUserValid(toUSerId, m.connectionPool.db) {
		return errors.New("can't send friendship request. user not valid")
	}

	insertQuery := `insert into notifications(from_user_id, to_user_id, type) 
					values ($1, $2, 'friendship_request');`

	_, err := m.connectionPool.db.Exec(insertQuery, fromUserId, toUSerId)
	if err != nil {
		return err
	}

	return nil
}

func (m *UserManager) getUserFriendsForGroup(userId string, groupId string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get user friends. user not valid")
	}

	getQuery := `select s.user_id
					,s.first_name
					,coalesce(s.last_name, '-') last_name
					,coalesce(s.phone, '-') phone
				from users s
				,friends f
				where f.user_id = $1
				and s.user_id = f.friend_id
				and not exists (select *
								from group_members m
								where m.group_id = $2
								and m.user_id = f.friend_id)
				and not exists (select *
							    from notifications i
								where i.group_id = $2
								and i.to_user_id = f.friend_id
								and i.status = 'N'
								and i.type = 'group_invitation');`

	rows, err := m.connectionPool.db.Query(getQuery, userId, groupId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	friends := make([]map[string]string, 0)

	for rows.Next() {
		var friendId string
		var friendFirstName string
		var friendLastName string
		var friendPhone string
		err = rows.Scan(&friendId, &friendFirstName, &friendLastName, &friendPhone)
		if err != nil {
			return nil, err
		}
		friend := make(map[string]string)
		friend["friendId"] = friendId
		friend["friendFirstName"] = friendFirstName
		friend["friendLastName"] = friendLastName
		friend["friendPhone"] = friendPhone

		friends = append(friends, friend)
	}

	response := make(map[string][]map[string]string)
	response["friends"] = friends

	return response, nil
}

func (m *UserManager) addUserToGroup(userId string, groupId string, userRole string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't add user to group. user not valid")
	}

	query := `create or replace procedure addUserToGroup(groupId character varying
														,userId  character varying
														,user_role character varying)
				language plpgsql
				as $$
				begin 
				--
				insert into group_members (group_id, user_id, user_role)
				select groupId, userId, user_role
				where not exists (select *
					from group_members m
					where m.group_id = groupId
					and m.user_id = userId);
				--
				insert into notifications(from_user_id, to_user_id, notification_text, group_id)
				select s.to_user_id, s.from_user_id, 'Accepted your invitation to ', s.group_id
				from notifications s
				where s.group_id = groupId
				and s.to_user_id = userId
				and s.status = 'N'
				and s.type = 'group_invitation'
				fetch first 1 row only;
				--
				update notifications
			 	set status = 'A'
				where group_id = groupId
				and to_user_id = userId
				and status = 'N'
				and type = 'group_invitation';
				--
				commit;
				--
				end;$$`

	_, err := m.connectionPool.db.Exec(query)
	if err != nil {
		return err
	}

	exequteQuery := `call addUserToGroup($1, $2, $3);`

	_, err = m.connectionPool.db.Exec(exequteQuery, groupId, userId, userRole)
	if err != nil {
		return err
	}

	return nil
}

func (m *UserManager) leaveGroup(userId string, groupId string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't leave group. user not valid")
	}

	deleteQuery := `delete from group_members where group_id = $1 and user_id = $2`

	_, err := m.connectionPool.db.Exec(deleteQuery, groupId, userId)
	if err != nil {
		return err
	}

	return nil
}

func (m *UserManager) changePassword(userId string, oldPassword string, newPassword string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't change password. user not valid")
	}

	var actualPassword string
	getQuery := `select s.password from users s where s.user_id = $1`
	if err := m.connectionPool.db.QueryRow(getQuery, userId).Scan(&actualPassword); err != nil {
		return err
	}

	oldPasswordhHash := sha256.New()
	oldPasswordhHash.Write([]byte(oldPassword))
	oldPasswordhMd := oldPasswordhHash.Sum(nil)
	oldPasswordhMdStr := hex.EncodeToString(oldPasswordhMd)

	if oldPasswordhMdStr != actualPassword {
		return errors.New("incorrect password")
	}

	newPasswordHash := sha256.New()
	newPasswordHash.Write([]byte(newPassword))
	newPasswordMd := newPasswordHash.Sum(nil)
	newPasswordMdStr := hex.EncodeToString(newPasswordMd)

	updateQuery := `update users set password = $1 where user_id = $2`

	_, err := m.connectionPool.db.Exec(updateQuery, newPasswordMdStr, userId)
	if err != nil {
		return err
	}

	return nil
}

func (m *UserManager) changePersonalInfo(userId string, birthDate string, age string, phoneNumber string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't change personal info. user not valid")
	}

	updateQuery := `update users set age = $1, phone = $2, birthdate = $3 where user_id = $4`

	_, err := m.connectionPool.db.Exec(updateQuery, age, phoneNumber, birthDate, userId)
	if err != nil {
		return err
	}

	return nil
}

func (m *UserManager) unfriend(userId string, friendId string) error {
	if !isUserValid(userId, m.connectionPool.db) || !isUserValid(friendId, m.connectionPool.db) {
		return errors.New("can't unfriend. user not valid")
	}

	query := `delete from friends
			where (user_id = $1
			and friend_id = $2)
			or (user_id = $2
				and friend_id = $1);`

	_, err := m.connectionPool.db.Exec(query, userId, friendId)
	if err != nil {
		return err
	}

	return nil
}

func (m *UserManager) assignAdminRole(userId string, memberId string, groupId string) error {
	if !isUserValid(userId, m.connectionPool.db) && !isUserValid(memberId, m.connectionPool.db) {
		return errors.New("can't assign admin role. user not valid")
	}

	updateQuery := `update group_members set user_role = 
					(case user_id
					when $2 then 'M'
					else 'A' end)
					where group_id = $1
					and user_id in ($2, $3)
					and exists(select *
						from group_members m
						where m.user_id = $2
						and group_id = $1)
					and exists(select *
						from group_members m
						where m.user_id = $3
						and group_id = $1);`

	_, err := m.connectionPool.db.Exec(updateQuery, groupId, userId, memberId)
	if err != nil {
		return err
	}

	insertQuery := `insert into notifications(from_user_id, to_user_id, notification_text, group_id)
					values ($1, $2, 'Granted you the Administrator rights of the ', $3);`

	_, _ = m.connectionPool.db.Exec(insertQuery, userId, memberId, groupId)

	return nil
}
