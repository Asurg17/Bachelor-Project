package main

import (
	"bytes"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"image"
	"image/png"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/websocket"
	_ "github.com/lib/pq"
)

const (
	host     = "localhost"
	port     = 5432
	user     = "postgres"
	password = ""
	dbname   = "sandrosurguladze"
)

// Structs

type GroupMembers struct {
	Members []string
}

type NewUser struct {
	Username    string
	FirstName   string
	LastName    string
	PhoneNumber string
	Password    string
}

type UserCredentials struct {
	Username string
	Password string
}

type UserIdentifier struct {
	UserId string
}

type GroupIdentifier struct {
	UserId  string
	GroupId string
}

type SearchGroupIdentifier struct {
	UserId          string
	GroupIdentifier string
}

type Group struct {
	UserId           string
	GroupName        string
	GroupDescription string
	MembersCount     string
	IsPrivate        string
}

type GroupChangedValues struct {
	UserId           string
	GroupId          string
	GroupName        string
	GroupDescription string
}

type UserPassword struct {
	UserId      string
	OldPassword string
	NewPassword string
}

type UserPersonalInfo struct {
	UserId      string
	Age         string
	PhoneNumber string
	BirthDate   string
}

type Image struct {
	ImageKey string
	Image    string
}

type ImageIdentifier struct {
	ImageKey string
}

type FreindshipRequest struct {
	FromUserId string
	ToUserId   string
}

type FreindshipAcceptResponse struct {
	UserId           string
	FromUserId       string
	RequestUniqueKey string
}

type FreindshipRejectResponse struct {
	UserId           string
	RequestUniqueKey string
}

type InvitationAcceptResponse struct {
	UserId           string
	FromUserId       string
	GroupId          string
	RequestUniqueKey string
}

type InvitationRejectResponse struct {
	UserId           string
	RequestUniqueKey string
}

type Message struct {
	MessageId string
	Type      string
	SenderId  string
	GroupId   string
	Content   string
	SendDate  string
}

//  ################################################################################################################

func openConnection() (db *sql.DB, err error) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)
	db, err = sql.Open("postgres", psqlconn)
	return
}

func isUserValid(userId string, db *sql.DB) bool {
	getQuery := `select s.user_id
				from users s
				where s.user_id = $1;`

	_, err := db.Exec(getQuery, userId)
	if err != nil {
		return false
	}

	return !(userId == "")
}

func registerNewUser(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	var newUser NewUser

	err = json.NewDecoder(req.Body).Decode(&newUser)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	passwordHash := sha256.New()
	passwordHash.Write([]byte(newUser.Password))
	passwordMd := passwordHash.Sum(nil)
	passwordMdStr := hex.EncodeToString(passwordMd)

	userId := newUser.Username + passwordMdStr

	insertQuery := `insert into "users" ("username", "password", "first_name", "last_name", "user_id", "phone")
					values ($1, $2, $3, $4, $5, $6)`
	_, err = db.Exec(insertQuery, newUser.Username, passwordMdStr, newUser.FirstName, newUser.LastName, userId, newUser.PhoneNumber)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	resp := make(map[string]string)
	resp["userId"] = userId
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func validateUser(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	var userCredentials UserCredentials

	err = json.NewDecoder(req.Body).Decode(&userCredentials)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	var actualPassword string
	var userId string
	getQuery := `select s.password, s.user_id from users s where s.username = $1`
	if err := db.QueryRow(getQuery, userCredentials.Username).Scan(&actualPassword, &userId); err != nil {
		if err == sql.ErrNoRows {
			w.Header().Set("Error", "No such username!")
			w.WriteHeader(400)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	hash := sha256.New()
	hash.Write([]byte(userCredentials.Password))
	md := hash.Sum(nil)
	mdStr := hex.EncodeToString(md)

	if mdStr != actualPassword {
		w.Header().Set("Error", "Incorrect Password!")
		w.WriteHeader(400)
		http.Error(w, "Incorrect Password!", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	resp := make(map[string]string)
	resp["userId"] = userId
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func getUserInfo(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {

		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var userIdentifier UserIdentifier

	err = json.NewDecoder(req.Body).Decode(&userIdentifier)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if userIdentifier.UserId == "" || !isUserValid(userIdentifier.UserId, db) {
		w.Header().Set("Error", "Can't get user Info!")
		w.WriteHeader(400)
		return
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

	if err := db.QueryRow(getQuery, userIdentifier.UserId).Scan(&username, &firstName, &lastName, &gender, &age, &location, &birthDate, &phone); err != nil {
		if err == sql.ErrNoRows {
			w.Header().Set("Error", "No user were found!")
			w.WriteHeader(400)
			return
		}
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	resp := make(map[string]string)
	resp["username"] = username
	resp["firstName"] = firstName
	resp["lastName"] = lastName
	resp["gender"] = gender
	resp["age"] = age
	resp["location"] = location
	resp["birthDate"] = birthDate
	resp["phone"] = phone
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func getUserGroups(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	defer db.Close()

	var user UserIdentifier

	err = json.NewDecoder(req.Body).Decode(&user)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if user.UserId == "" || !isUserValid(user.UserId, db) {
		w.Header().Set("Error", "Can't get user Groups!")
		w.WriteHeader(400)
		return
	}

	getQuery := `select s.group_id
					   ,s.group_title
					   ,s.group_description
					   ,s.group_capacity
					   ,(select count(*)
					    from group_members 
						where group_id = m.group_id) members_count
				from groups s
					,group_members m
				where s.group_id = m.group_id
				and m.user_id = $1;`

	rows, err := db.Query(getQuery, user.UserId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
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
			w.Header().Set("Error", err.Error())
			w.WriteHeader(500)
			return
		}
		group := make(map[string]string)
		group["groupId"] = groupId
		group["groupTitle"] = groupTitle
		group["groupDescription"] = groupDescription
		group["groupCapacity"] = groupCapacity
		group["groupMembersNum"] = groupMembersNum

		groups = append(groups, group)
	}

	response := make(map[string][]map[string]string)
	response["groups"] = groups

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func searchNewGroups(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	defer db.Close()

	var groupIdentifier SearchGroupIdentifier

	err = json.NewDecoder(req.Body).Decode(&groupIdentifier)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if groupIdentifier.UserId == "" || !isUserValid(groupIdentifier.UserId, db) {
		w.Header().Set("Error", "Can't search Groups!")
		w.WriteHeader(400)
		return
	}

	getQuery := "select g.group_id, g.group_title, g.group_description, " +
		" g.group_capacity, (select count(*) from group_members where group_id = g.group_id) members_count " +
		"from groups g " +
		"where (lower(g.group_title) like lower('%" + groupIdentifier.GroupIdentifier + "%') " +
		"or lower(g.group_description) like lower('%" + groupIdentifier.GroupIdentifier + "%')) " +
		//"and (select count(*) from group_members m where m.group_id = g.group_id) < g.group_capacity " +
		"and not exists(select * from group_members m where m.group_id = g.group_id and m.user_id = $1) " +
		"and exists (select * from users s where s.user_id = $1) " +
		"order by lower(g.group_title);"

	rows, err := db.Query(getQuery, groupIdentifier.UserId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
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
			w.Header().Set("Error", err.Error())
			w.WriteHeader(500)
			return
		}
		group := make(map[string]string)
		group["groupId"] = groupId
		group["groupTitle"] = groupTitle
		group["groupDescription"] = groupDescription
		group["groupCapacity"] = groupCapacity
		group["groupMembersNum"] = groupMembersNum

		groups = append(groups, group)
	}

	response := make(map[string][]map[string]string)
	response["groups"] = groups

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func addUserToGroup(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var groupIdentifier GroupIdentifier

	err = json.NewDecoder(req.Body).Decode(&groupIdentifier)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if groupIdentifier.UserId == "" || !isUserValid(groupIdentifier.UserId, db) {
		w.Header().Set("Error", "Can't add user to Group!")
		w.WriteHeader(400)
		return
	}

	query := `create or replace procedure addUserToGroup(groupId character varying
														,userId  character varying)
				language plpgsql
				as $$
				begin 
				insert into group_members (group_id, user_id)
				values (groupId, userId);

				update invitations
			 	set status = 'A'
				where group_id = groupId
				and to_user_id = userId; 
				end;$$`

	_, err = db.Exec(query)
	if err != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}

	exequteQuery := `call addUserToGroup($1, $2);`

	_, err = db.Exec(exequteQuery, groupIdentifier.GroupId, groupIdentifier.UserId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func getUserFriends(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	defer db.Close()

	var user UserIdentifier

	err = json.NewDecoder(req.Body).Decode(&user)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if user.UserId == "" || !isUserValid(user.UserId, db) {
		w.Header().Set("Error", "Can't get user friends!")
		w.WriteHeader(400)
		return
	}

	getQuery := `select s.user_id
					,s.first_name
					,coalesce(s.last_name, '-') last_name
					,coalesce(s.phone, '-') phone
				from users s
				,friends f
				where f.user_id = $1
				and s.user_id = f.friend_id;`

	rows, err := db.Query(getQuery, user.UserId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
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
			w.Header().Set("Error", err.Error())
			w.WriteHeader(500)
			return
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

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func getUserFriendsForGroup(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	defer db.Close()

	var groupIdentifier GroupIdentifier

	err = json.NewDecoder(req.Body).Decode(&groupIdentifier)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if groupIdentifier.UserId == "" || !isUserValid(groupIdentifier.UserId, db) {
		w.Header().Set("Error", "Can't get user friends!")
		w.WriteHeader(400)
		return
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
							    from invitations i
								where i.group_id = $2
								and i.to_user_id = f.friend_id
								and i.status = 'N');`

	rows, err := db.Query(getQuery, groupIdentifier.UserId, groupIdentifier.GroupId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
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
			w.Header().Set("Error", err.Error())
			w.WriteHeader(500)
			return
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

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func getGroupMembers(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	defer db.Close()

	var groupIdentifier GroupIdentifier

	err = json.NewDecoder(req.Body).Decode(&groupIdentifier)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if groupIdentifier.UserId == "" || !isUserValid(groupIdentifier.UserId, db) {
		w.Header().Set("Error", "Can't get group members!")
		w.WriteHeader(400)
		return
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

	rows, err := db.Query(getQuery, groupIdentifier.UserId, groupIdentifier.GroupId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
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
			w.Header().Set("Error", err.Error())
			w.WriteHeader(500)
			return
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

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func changePassword(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var userPassword UserPassword

	err = json.NewDecoder(req.Body).Decode(&userPassword)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if userPassword.UserId == "" || !isUserValid(userPassword.UserId, db) {
		w.Header().Set("Error", "Can't change password!")
		w.WriteHeader(400)
		return
	}

	var actualPassword string
	getQuery := `select s.password from users s where s.user_id = $1`
	if err := db.QueryRow(getQuery, userPassword.UserId).Scan(&actualPassword); err != nil {
		if err == sql.ErrNoRows {
			w.Header().Set("Error", "Can't update password!")
			w.WriteHeader(500)
			return
		}
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	oldPasswordhHash := sha256.New()
	oldPasswordhHash.Write([]byte(userPassword.OldPassword))
	oldPasswordhMd := oldPasswordhHash.Sum(nil)
	oldPasswordhMdStr := hex.EncodeToString(oldPasswordhMd)

	if oldPasswordhMdStr != actualPassword {
		w.Header().Set("Error", "Incorrect Password!")
		w.WriteHeader(400)
		return
	}

	newPasswordHash := sha256.New()
	newPasswordHash.Write([]byte(userPassword.NewPassword))
	newPasswordMd := newPasswordHash.Sum(nil)
	newPasswordMdStr := hex.EncodeToString(newPasswordMd)

	updateQuery := `update users set password = $1 where user_id = $2`

	_, e := db.Exec(updateQuery, newPasswordMdStr, userPassword.UserId)
	if e != nil {
		w.Header().Set("Error", "Can't update password!")
		w.WriteHeader(500)
		return
	}
}

func changePersonalInfo(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var userPersonalInfo UserPersonalInfo

	err = json.NewDecoder(req.Body).Decode(&userPersonalInfo)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if userPersonalInfo.UserId == "" || !isUserValid(userPersonalInfo.UserId, db) {
		w.Header().Set("Error", "Can't change personal info!")
		w.WriteHeader(400)
		return
	}

	updateQuery := `update users set age = $1, phone = $2, birthdate = $3 where user_id = $4`

	_, e := db.Exec(updateQuery, userPersonalInfo.Age, userPersonalInfo.PhoneNumber, userPersonalInfo.BirthDate, userPersonalInfo.UserId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

func uploadImage(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	imageFolderPath := "./images"
	imageKey := req.URL.Query().Get("imageKey")

	if _, err := os.Stat(imageFolderPath); os.IsNotExist(err) {
		err := os.Mkdir(imageFolderPath, os.ModePerm)
		if err != nil {
			w.Header().Set("Error", err.Error())
			w.WriteHeader(500)
			return
		}
	}

	imgBytes, _ := ioutil.ReadAll(req.Body)
	img, _, _ := image.Decode(bytes.NewReader(imgBytes))
	out, err := os.Create(imageFolderPath + "/" + imageKey + ".png")

	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	err = png.Encode(out, img)

	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func getImage(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	imageFolderPath := "./images"
	imageKey := req.URL.Query().Get("imageKey")
	dat, _ := os.ReadFile(imageFolderPath + "/" + imageKey + ".png")
	w.Write(dat)
}

func createGroup(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var group Group

	err = json.NewDecoder(req.Body).Decode(&group)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if group.UserId == "" || !isUserValid(group.UserId, db) {
		w.Header().Set("Error", "Can't create new group!")
		w.WriteHeader(400)
		return
	}

	groupId := group.GroupName + group.UserId

	insertQuery := `insert into "groups" ("group_id", "group_title", "group_description", "group_capacity", "creator_id", "is_private") 
					values ($1, $2, $3, $4, $5, $6)`
	_, e := db.Exec(insertQuery, groupId, group.GroupName, group.GroupDescription, group.MembersCount, group.UserId, group.IsPrivate)
	if e != nil {
		w.Header().Set("Error", e.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	resp := make(map[string]string)
	resp["groupId"] = groupId
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func addGroupMembers(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	userId := req.URL.Query().Get("userId")
	groupId := req.URL.Query().Get("groupId")
	addSelfToGroup := req.URL.Query().Get("addSelfToGroup")

	if userId == "" || !isUserValid(userId, db) {
		w.Header().Set("Error", "Can't add group members. User not Valid!")
		w.WriteHeader(400)
		return
	}

	var groupMembers GroupMembers
	dataBytes, _ := ioutil.ReadAll(req.Body)
	e := json.Unmarshal(dataBytes, &groupMembers)
	if e != nil {
		w.Header().Set("Error", e.Error())
		w.WriteHeader(500)
		return
	}

	if addSelfToGroup == "Y" {
		query := `insert into group_members ("group_id", "user_id", "user_role") 
						values ($1, $2, $3)`
		_, e = db.Exec(query, groupId, userId, "A")
		if e != nil {
			w.Header().Set("Error", e.Error())
			w.WriteHeader(500)
			return
		}
	}

	for _, groupMemberId := range groupMembers.Members {
		query := `insert into invitations ("from_user_id", "to_user_id", "group_id") 
						values ($1, $2, $3)`
		_, e = db.Exec(query, userId, groupMemberId, groupId)
		if e != nil {
			w.Header().Set("Error", e.Error())
			w.WriteHeader(500)
			return
		}
	}
}

func saveGroupUpdates(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var groupChangedValues GroupChangedValues

	err = json.NewDecoder(req.Body).Decode(&groupChangedValues)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if groupChangedValues.UserId == "" || !isUserValid(groupChangedValues.UserId, db) {
		w.Header().Set("Error", "Can't save updates!")
		w.WriteHeader(400)
		return
	}

	updateQuery := `update groups set group_title = $1, group_description = $2  where group_id = $3 and exists(select * from users s where s.user_id = $4)`

	_, e := db.Exec(updateQuery, groupChangedValues.GroupName, groupChangedValues.GroupDescription, groupChangedValues.GroupId, groupChangedValues.UserId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

func leaveGroup(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var groupIdentifier GroupIdentifier

	err = json.NewDecoder(req.Body).Decode(&groupIdentifier)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if groupIdentifier.UserId == "" || !isUserValid(groupIdentifier.UserId, db) {
		w.Header().Set("Error", "Error!")
		w.WriteHeader(400)
		return
	}

	deleteQuery := `delete from group_members where group_id = $1 and user_id = $2`

	_, e := db.Exec(deleteQuery, groupIdentifier.GroupId, groupIdentifier.UserId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

func sendFriendshipRequest(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var freindshipRequest FreindshipRequest

	err = json.NewDecoder(req.Body).Decode(&freindshipRequest)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if freindshipRequest.FromUserId == "" || freindshipRequest.ToUserId == "" || !isUserValid(freindshipRequest.FromUserId, db) || !isUserValid(freindshipRequest.ToUserId, db) {
		w.Header().Set("Error", "Can't send friendship request!")
		w.WriteHeader(400)
		return
	}

	insertQuery := `insert into friendship_requests(from_user_id, to_user_id) 
					values ($1, $2);`

	_, e := db.Exec(insertQuery, freindshipRequest.FromUserId, freindshipRequest.ToUserId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

func getUserNotifications(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	defer db.Close()

	var userIdentifier UserIdentifier

	err = json.NewDecoder(req.Body).Decode(&userIdentifier)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if userIdentifier.UserId == "" || !isUserValid(userIdentifier.UserId, db) {
		w.Header().Set("Error", "Can't get notifications!")
		w.WriteHeader(400)
		return
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
					,invitation_date
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

	// getQuery := `select r.id,
	// 					s.user_id,
	// 					s.first_name || ' ' || s.last_name whole_name,
	// 					true is_friendship_request
	// 			from friendship_requests r,
	// 				users s
	// 			where s.user_id = from_user_id
	// 			and r.to_user_id = $1
	// 			and r.status = 'N'
	// 			order by request_date desc;`

	rows, err := db.Query(getQuery, userIdentifier.UserId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
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
			w.Header().Set("Error", err.Error())
			w.WriteHeader(500)
			return
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

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
	}
	w.Write(jsonResp)
}

func acceptFriendshipRequest(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var freindshipResponse FreindshipAcceptResponse

	err = json.NewDecoder(req.Body).Decode(&freindshipResponse)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if freindshipResponse.UserId == "" || freindshipResponse.FromUserId == "" || !isUserValid(freindshipResponse.UserId, db) || !isUserValid(freindshipResponse.FromUserId, db) {
		w.Header().Set("Error", "Can't accept friendship. User not Valid!")
		w.WriteHeader(400)
		return
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

	_, err = db.Exec(query)
	if err != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}

	exequteQuery := `call acceptFriendship($1, $2, $3);`

	_, err = db.Exec(exequteQuery, freindshipResponse.RequestUniqueKey, freindshipResponse.FromUserId, freindshipResponse.UserId)
	if err != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

func rejectFriendshipRequest(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var freindshipResponse FreindshipRejectResponse

	err = json.NewDecoder(req.Body).Decode(&freindshipResponse)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if freindshipResponse.UserId == "" || !isUserValid(freindshipResponse.UserId, db) {
		w.Header().Set("Error", "Can't reject friendship. User not valid!")
		w.WriteHeader(400)
		return
	}

	updateQuery := `update friendship_requests
					set status = 'R'
					where id = $1
					and to_user_id = $2;`

	_, e := db.Exec(updateQuery, freindshipResponse.RequestUniqueKey, freindshipResponse.UserId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

func acceptInvitation(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var invitationResponse InvitationAcceptResponse

	err = json.NewDecoder(req.Body).Decode(&invitationResponse)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if invitationResponse.UserId == "" || invitationResponse.FromUserId == "" || !isUserValid(invitationResponse.UserId, db) || !isUserValid(invitationResponse.FromUserId, db) {
		w.Header().Set("Error", "Can't accept invitation. User not valid!")
		w.WriteHeader(400)
		return
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

	_, err = db.Exec(query)
	if err != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}

	insertQuery := `call acceptInvitation($1, $2, $3, $4);`

	_, err = db.Exec(insertQuery, invitationResponse.RequestUniqueKey, invitationResponse.GroupId, invitationResponse.FromUserId, invitationResponse.UserId)
	if err != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

func rejectInvitation(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var invitationResponse InvitationRejectResponse

	err = json.NewDecoder(req.Body).Decode(&invitationResponse)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if invitationResponse.UserId == "" || !isUserValid(invitationResponse.UserId, db) {
		w.Header().Set("Error", "Can't reject invitation. User not valid!")
		w.WriteHeader(400)
		return
	}

	updateQuery := `update invitations
					set status = 'R'
					where id = $1
					and to_user_id = $2;`

	_, e := db.Exec(updateQuery, invitationResponse.RequestUniqueKey, invitationResponse.UserId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

func sendMessage(w http.ResponseWriter, req *http.Request) {

	db, err := openConnection()
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	defer db.Close()

	var message Message

	err = json.NewDecoder(req.Body).Decode(&message)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	if message.SenderId == "" || !isUserValid(message.SenderId, db) {
		w.Header().Set("Error", "Can't send message. User not Valid!")
		w.WriteHeader(400)
		return
	}

	query := `insert into messages(message_id, type, sender_id, group_id, content, send_date)
				values ($1, $2, $3, $4, $5, $6);`

	_, err = db.Exec(query, message.MessageId, message.Type, message.SenderId, message.GroupId, message.Content, message.SendDate)
	if err != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(500)
		return
	}
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

func reader(conn *websocket.Conn) {
	for {
		messageType, p, err := conn.ReadMessage()
		if err != nil {
			log.Println(err)
			return
		}

		log.Println(string(p))

		if err := conn.WriteMessage(messageType, p); err != nil {
			log.Println(err)
			return
		}

	}
}

func notificationsWsEndpoint(w http.ResponseWriter, req *http.Request) {
	upgrader.CheckOrigin = func(req *http.Request) bool { return true }

	ws, err := upgrader.Upgrade(w, req, nil)
	if err != nil {
		log.Println(err)
	}

	log.Println("Client Successfully Connected!")

	reader(ws)
}

func main() {
	setupRoutes()
}

func setupRoutes() {

	http.HandleFunc("/ws", notificationsWsEndpoint)

	http.HandleFunc("/getImage", getImage)
	http.HandleFunc("/leaveGroup", leaveGroup)
	http.HandleFunc("/getUserInfo", getUserInfo)
	http.HandleFunc("/uploadImage", uploadImage)
	http.HandleFunc("/createGroup", createGroup)
	http.HandleFunc("/validateUser", validateUser)
	http.HandleFunc("/getUserGroups", getUserGroups)
	http.HandleFunc("/registerNewUser", registerNewUser)
	http.HandleFunc("/getUserFriends", getUserFriends)
	http.HandleFunc("/getUserFriendsForGroup", getUserFriendsForGroup)
	http.HandleFunc("/addUserToGroup", addUserToGroup)
	http.HandleFunc("/getGroupMembers", getGroupMembers)
	http.HandleFunc("/changePassword", changePassword)
	http.HandleFunc("/addGroupMembers", addGroupMembers)
	http.HandleFunc("/searchNewGroups", searchNewGroups)
	http.HandleFunc("/saveGroupUpdates", saveGroupUpdates)
	http.HandleFunc("/changePersonalInfo", changePersonalInfo)
	http.HandleFunc("/getUserNotifications", getUserNotifications)
	http.HandleFunc("/sendFriendshipRequest", sendFriendshipRequest)
	http.HandleFunc("/acceptFriendshipRequest", acceptFriendshipRequest)
	http.HandleFunc("/rejectFriendshipRequest", rejectFriendshipRequest)
	http.HandleFunc("/acceptInvitation", acceptInvitation)
	http.HandleFunc("/rejectInvitation", rejectInvitation)

	http.HandleFunc("/sendMessage", sendMessage)

	http.ListenAndServe(":9000", nil)
}

// ########################################################################################################################
// ########################################################################################################################
// ########################################################################################################################

// // handle `/` route
// http.HandleFunc("/", func(res http.ResponseWriter, req *http.Request) {
// 	fmt.Fprint(res, "Hello World!")
// })
// log.Fatal(http.ListenAndServeTLS(":9000", "localhost.crt", "localhost.key", nil))
// http.HandleFunc("/registerClient", registerClient)

// func CheckError(err error) {
// 	if err != nil {
// 		panic(err)
// 	}
// }

// func init() {

// 	connStr := "postgres://postgres:password@localhost/retrievetest?sslmode=disable"
// 	db, err = sql.Open("postgres", connStr)

// 	if err != nil {
// 	panic(err)
// }

//always connected or when called?
