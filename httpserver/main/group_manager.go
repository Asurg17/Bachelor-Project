package main

import (
	"database/sql"
	"errors"
)

type GroupManager struct {
	connectionPool *PGConnectionPool
}

func NewGroupManager(connectionPool *PGConnectionPool) *GroupManager {
	groupManager := new(GroupManager)
	groupManager.connectionPool = connectionPool
	return groupManager
}

// Manager Functions

func (m *GroupManager) searchNewGroups(userId string, groupIdentifier string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't search new groups. user not valid")
	}

	getQuery := `select g.group_id,
						g.group_title,
						g.group_description,
				 		g.group_capacity,
						(select count(*) 
						from group_members
						where group_id = g.group_id) members_count
				from groups g
				where (lower(g.group_title) like lower('%' || $2 || '%')
				or lower(g.group_description) like lower('%' || $2 || '%'))
				and not exists(select * from group_members m where m.group_id = g.group_id and m.user_id = $1)
				and exists (select * from users s where s.user_id = $1)
				order by lower(g.group_title);`

	rows, err := m.connectionPool.db.Query(getQuery, userId, groupIdentifier)
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
		err = rows.Scan(&groupId, &groupTitle, &groupDescription, &groupCapacity, &groupMembersNum)
		if err != nil {
			return nil, err
		}
		group := make(map[string]string)
		group["groupId"] = groupId
		group["groupTitle"] = groupTitle
		group["groupDescription"] = groupDescription
		group["groupCapacity"] = groupCapacity
		group["groupMembersNum"] = groupMembersNum
		group["userRole"] = "M"

		groups = append(groups, group)
	}

	response := make(map[string][]map[string]string)
	response["groups"] = groups

	return response, nil
}

func (m *GroupManager) getGroupMembers(userId string, groupId string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get group members. user not valid")
	}

	getQuery := `select s.user_id
				,s.first_name
				,coalesce(s.last_name, '-') last_name
				,coalesce(s.phone, '-') phone
				,(select coalesce(max('Y'), 'N')
						from friendship_requests r
						where ((r.from_user_id = $1
									and r.to_user_id = s.user_id)
								or 
								(r.to_user_id = $1
									and r.from_user_id = s.user_id))
							and r.status = 'N') is_already_sent
				,(select coalesce(max('Y'), case when s.user_id = $1 then 'Y' else 'N' end)
						from friends f
						where f.user_id = $1
						and f.friend_id = s.user_id) are_already_friends
				from users s
				,group_members m
				where m.group_id = $2
				and s.user_id = m.user_id
				and exists(select *
							from users
							where user_id = $1)
				order by case when m.user_id = $1 then 1
						 else 2 end, lower(s.first_name)`

	rows, err := m.connectionPool.db.Query(getQuery, userId, groupId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	members := make([]map[string]string, 0)

	for rows.Next() {
		var memberId string
		var memberFirstName string
		var memberLastName string
		var memberPhone string
		var isFriendRequestAlreadySent string
		var areAlreadyFriends string
		err = rows.Scan(&memberId, &memberFirstName, &memberLastName, &memberPhone, &isFriendRequestAlreadySent, &areAlreadyFriends)
		if err != nil {
			return nil, err
		}
		member := make(map[string]string)
		member["memberId"] = memberId
		member["memberFirstName"] = memberFirstName
		member["memberLastName"] = memberLastName
		member["memberPhone"] = memberPhone
		member["isFriendRequestAlreadySent"] = isFriendRequestAlreadySent
		member["areAlreadyFriends"] = areAlreadyFriends

		members = append(members, member)
	}

	response := make(map[string][]map[string]string)
	response["members"] = members

	return response, nil
}

func (m *GroupManager) createGroup(userId string, groupName string, groupDescription string, membersCount string, isPrivate string) (map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't create group. user not valid")
	}

	groupId := groupName + userId

	insertQuery := `insert into "groups" ("group_id", "group_title", "group_description", "group_capacity", "creator_id", "is_private") 
					values ($1, $2, $3, $4, $5, $6)`
	_, err := m.connectionPool.db.Exec(insertQuery, groupId, groupName, groupDescription, membersCount, userId, isPrivate)
	if err != nil {
		return nil, err
	}

	response := make(map[string]string)
	response["groupId"] = groupId

	return response, nil
}

func (m *GroupManager) saveGroupUpdates(userId string, groupId string, groupName string, groupDescription string) error {
	if !isUserValid(userId, m.connectionPool.db) {
		return errors.New("can't save changes. user not valid")
	}

	updateQuery := `update groups set group_title = $1, group_description = $2  where group_id = $3 and exists(select * from users s where s.user_id = $4)`

	_, err := m.connectionPool.db.Exec(updateQuery, groupName, groupDescription, groupId, userId)
	if err != nil {
		return err
	}

	return nil
}

func (m *GroupManager) getGroupMediaFiles(userId string, groupId string) (map[string][]map[string]string, error) {
	if !isUserValid(userId, m.connectionPool.db) {
		return nil, errors.New("can't get group media files. user not valid")
	}

	getQuery := `select s.content,
						s.message_id
				from messages s
				where s.group_id = $1
				and type = 'photo'
				order by s.send_date_timestamp;`

	rows, err := m.connectionPool.db.Query(getQuery, groupId)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	defer rows.Close()

	mediaFiles := make([]map[string]string, 0)

	for rows.Next() {
		var imageURL string
		var messageId string
		err = rows.Scan(&imageURL, &messageId)
		if err != nil {
			return nil, err
		}
		mediaFile := make(map[string]string)
		mediaFile["imageURL"] = imageURL
		mediaFile["messageId"] = messageId

		mediaFiles = append(mediaFiles, mediaFile)
	}

	response := make(map[string][]map[string]string)
	response["mediaFiles"] = mediaFiles

	return response, nil
}