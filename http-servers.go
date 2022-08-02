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
	"net/http"
	"os"

	_ "github.com/lib/pq"
)

const (
	host     = "localhost"
	port     = 5432
	user     = "postgres"
	password = ""
	dbname   = "sandrosurguladze"
)

func registerClient(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	username := req.URL.Query().Get("username")
	firstName := req.URL.Query().Get("firstName")
	lastName := req.URL.Query().Get("lastName")
	phoneNumber := req.URL.Query().Get("phoneNumber")
	password := req.URL.Query().Get("password")

	passwordHash := sha256.New()
	passwordHash.Write([]byte(password))
	passwordMd := passwordHash.Sum(nil)
	passwordMdStr := hex.EncodeToString(passwordMd)

	userId := username + passwordMdStr

	insertQuery := `insert into "users" ("username", "password", "first_name", "last_name", "user_id", "phone") 
					values ($1, $2, $3, $4, $5, $6)`
	_, e := db.Exec(insertQuery, username, passwordMdStr, firstName, lastName, userId, phoneNumber)
	if e != nil {
		w.Header().Set("Error", e.Error())
		w.WriteHeader(400)
		http.Error(w, e.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	resp := make(map[string]string)
	resp["userId"] = userId
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		print("Error happened in JSON marshal. Err: %s", err)
	}
	w.Write(jsonResp)
}

func validateUser(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	username := req.URL.Query().Get("username")
	givenPassword := req.URL.Query().Get("password")

	var actualPassword string
	var userId string
	getQuery := `select s.password, s.user_id from users s where s.username = $1`
	if err := db.QueryRow(getQuery, username).Scan(&actualPassword, &userId); err != nil {
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
	hash.Write([]byte(givenPassword))
	md := hash.Sum(nil)
	mdStr := hex.EncodeToString(md)

	if mdStr != actualPassword {
		w.Header().Set("Error", "Incorrect Password!")
		w.WriteHeader(400)
		http.Error(w, "Incorrect Password!", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	resp := make(map[string]string)
	resp["userId"] = userId
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		print("Error happened in JSON marshal. Err: %s", err)
	}
	w.Write(jsonResp)
}

func getUserInfo(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	userId := req.URL.Query().Get("userId")

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

	if err := db.QueryRow(getQuery, userId).Scan(&username, &firstName, &lastName, &gender, &age, &location, &birthDate, &phone); err != nil {
		if err == sql.ErrNoRows {
			w.Header().Set("Error", "No user were found!")
			w.WriteHeader(400)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
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
		print("Error happened in JSON marshal. Err: %s", err)
	}
	w.Write(jsonResp)
}

func getUserGroups(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	userId := req.URL.Query().Get("userId")

	getQuery := `select s.group_id
					   ,s.group_title
					   ,s.group_description
				from groups s
					,group_members m
				where s.group_id = m.group_id
				and m.user_id = $1;`

	rows, err := db.Query(getQuery, userId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	groups := make([]map[string]string, 0)

	for rows.Next() {
		var groupId string
		var groupTitle string
		var groupDescription string
		err = rows.Scan(&groupId, &groupTitle, &groupDescription)
		if err != nil {
			w.Header().Set("Error", err.Error())
			w.WriteHeader(400)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		group := make(map[string]string)
		group["groupId"] = groupId
		group["groupTitle"] = groupTitle
		group["groupDescription"] = groupDescription

		groups = append(groups, group)
	}

	response := make(map[string][]map[string]string)
	response["groups"] = groups

	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		print("Error happened in JSON marshal. Err: %s", err)
	}
	w.Write(jsonResp)
}

func searchNewGroups(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	userId := req.URL.Query().Get("userId")
	groupIdentifier := req.URL.Query().Get("groupIdentifier")

	getQuery := "select g.group_id, g.group_title, g.group_description " +
		"from groups g " +
		"where (lower(g.group_title) like lower('%" + groupIdentifier + "%') " +
		"or lower(g.group_description) like lower('%" + groupIdentifier + "%')) " +
		"and (select count(*) from group_members m where m.group_id = g.group_id) < g.group_capacity " +
		"and not exists(select * from group_members m where m.group_id = g.group_id and m.user_id = $1) " +
		"and exists (select * from users s where s.user_id = $1) " +
		"order by lower(g.group_title);"

	rows, err := db.Query(getQuery, userId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	groups := make([]map[string]string, 0)

	for rows.Next() {
		var groupId string
		var groupTitle string
		var groupDescription string
		err = rows.Scan(&groupId, &groupTitle, &groupDescription)
		if err != nil {
			w.Header().Set("Error", err.Error())
			w.WriteHeader(400)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		group := make(map[string]string)
		group["groupId"] = groupId
		group["groupTitle"] = groupTitle
		group["groupDescription"] = groupDescription

		groups = append(groups, group)
	}

	response := make(map[string][]map[string]string)
	response["groups"] = groups

	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		print("Error happened in JSON marshal. Err: %s", err)
	}
	w.Write(jsonResp)
}

func getUserFriends(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	userId := req.URL.Query().Get("userId")

	getQuery := `select s.user_id
					,s.first_name
					,coalesce(s.last_name, '-') last_name
					,coalesce(s.phone, '-') phone
				from users s
				,friends f
				where f.user_id = $1
				and s.user_id = f.friend_id;`

	rows, err := db.Query(getQuery, userId)
	if err != nil && err != sql.ErrNoRows {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		http.Error(w, err.Error(), http.StatusInternalServerError)
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
			w.WriteHeader(400)
			http.Error(w, err.Error(), http.StatusInternalServerError)
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

	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		print("Error happened in JSON marshal. Err: %s", err)
	}
	w.Write(jsonResp)
}

func changePassword(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	userId := req.URL.Query().Get("userId")
	oldPassword := req.URL.Query().Get("oldPassword")
	newPassword := req.URL.Query().Get("newPassword")

	var actualPassword string
	getQuery := `select s.password from users s where s.user_id = $1`
	if err := db.QueryRow(getQuery, userId).Scan(&actualPassword); err != nil {
		if err == sql.ErrNoRows {
			w.Header().Set("Error", "Can't update password!")
			w.WriteHeader(400)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	oldPasswordhHash := sha256.New()
	oldPasswordhHash.Write([]byte(oldPassword))
	oldPasswordhMd := oldPasswordhHash.Sum(nil)
	oldPasswordhMdStr := hex.EncodeToString(oldPasswordhMd)

	if oldPasswordhMdStr != actualPassword {
		w.Header().Set("Error", "Incorrect Password!")
		w.WriteHeader(400)
		http.Error(w, "Incorrect Password!", http.StatusInternalServerError)
		return
	}

	newPasswordHash := sha256.New()
	newPasswordHash.Write([]byte(newPassword))
	newPasswordMd := newPasswordHash.Sum(nil)
	newPasswordMdStr := hex.EncodeToString(newPasswordMd)

	updateQuery := `update users set password = $1 where user_id = $2`

	_, e := db.Exec(updateQuery, newPasswordMdStr, userId)
	if e != nil {
		w.Header().Set("Error", "Can't update password!")
		w.WriteHeader(400)
		http.Error(w, e.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func changePersonalInfo(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	userId := req.URL.Query().Get("userId")
	age := req.URL.Query().Get("age")
	phoneNumber := req.URL.Query().Get("phoneNumber")
	birthDate := req.URL.Query().Get("birthDate")

	updateQuery := `update users set age = $1, phone = $2, birthdate = $3 where user_id = $4`

	_, e := db.Exec(updateQuery, age, phoneNumber, birthDate, userId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(400)
		http.Error(w, e.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func uploadImage(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	imageFolderPath := "./images"
	imageKey := req.URL.Query().Get("imageKey")

	if _, err := os.Stat(imageFolderPath); os.IsNotExist(err) {
		err := os.Mkdir(imageFolderPath, os.ModePerm)
		if err != nil {
			print(err)
			w.Header().Set("Error", err.Error())
			w.WriteHeader(500)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}

	imgBytes, _ := ioutil.ReadAll(req.Body)
	img, _, _ := image.Decode(bytes.NewReader(imgBytes))
	out, err := os.Create(imageFolderPath + "/" + imageKey + ".png")

	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	err = png.Encode(out, img)

	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func getImage(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	imageFolderPath := "./images"
	imageKey := req.URL.Query().Get("imageKey")
	dat, _ := os.ReadFile(imageFolderPath + "/" + imageKey + ".png")

	w.Write(dat)
}

func createGroup(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	userId := req.URL.Query().Get("userId")
	groupName := req.URL.Query().Get("groupName")
	groupDescription := req.URL.Query().Get("groupDescription")
	membersCount := req.URL.Query().Get("membersCount")
	isPrivate := req.URL.Query().Get("isPrivate")

	groupId := groupName + userId

	insertQuery := `insert into "groups" ("group_id", "group_title", "group_description", "group_capacity", "creator_id", "is_private") 
					values ($1, $2, $3, $4, $5, $6)`
	_, e := db.Exec(insertQuery, groupId, groupName, groupDescription, membersCount, userId, isPrivate)
	if e != nil {
		w.Header().Set("Error", e.Error())
		w.WriteHeader(400)
		http.Error(w, e.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	resp := make(map[string]string)
	resp["groupId"] = groupId
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	w.Write(jsonResp)
}

type GroupMembers struct {
	Members []string
}

func addGroupMembers(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	userId := req.URL.Query().Get("userId")
	groupId := req.URL.Query().Get("groupId")

	var groupMembers GroupMembers
	dataBytes, _ := ioutil.ReadAll(req.Body)
	e := json.Unmarshal(dataBytes, &groupMembers)
	if e != nil {
		w.Header().Set("Error", e.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	adminInsertQuery := `insert into "group_members" ("group_id", "user_id", "user_role") 
						values ($1, $2, $3)`
	_, e = db.Exec(adminInsertQuery, groupId, userId, "A")
	if e != nil {
		w.Header().Set("Error", e.Error())
		w.WriteHeader(400)
		http.Error(w, e.Error(), http.StatusInternalServerError)
		return
	}

	for _, groupMemberId := range groupMembers.Members {
		memberInsertQuery := `insert into "group_members" ("group_id", "user_id", "user_role") 
						values ($1, $2, $3)`
		_, e = db.Exec(memberInsertQuery, groupId, groupMemberId, "M")
		if e != nil {
			w.Header().Set("Error", e.Error())
			w.WriteHeader(400)
			http.Error(w, e.Error(), http.StatusInternalServerError)
			return
		}
	}

}

func saveGroupUpdates(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	userId := req.URL.Query().Get("userId")
	groupId := req.URL.Query().Get("groupId")
	groupName := req.URL.Query().Get("groupName")
	groupDescription := req.URL.Query().Get("groupDescription")

	updateQuery := `update groups set group_title = $1, group_description = $2  where group_id = $3 and exists(select * from users s where s.user_id = $4)`

	_, e := db.Exec(updateQuery, groupName, groupDescription, groupId, userId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(400)
		http.Error(w, e.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func leaveGroup(w http.ResponseWriter, req *http.Request) {

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		print(err)
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	userId := req.URL.Query().Get("userId")
	groupId := req.URL.Query().Get("groupId")

	updateQuery := `delete from group_members where group_id = $1 and user_id = $2`

	_, e := db.Exec(updateQuery, groupId, userId)
	if e != nil {
		w.Header().Set("Error", "Can't save Changes!")
		w.WriteHeader(400)
		http.Error(w, e.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func main() {
	// // handle `/` route
	// http.HandleFunc("/", func(res http.ResponseWriter, req *http.Request) {
	// 	fmt.Fprint(res, "Hello World!")
	// })
	// log.Fatal(http.ListenAndServeTLS(":9000", "localhost.crt", "localhost.key", nil))
	// http.HandleFunc("/registerClient", registerClient)

	http.HandleFunc("/getImage", getImage)
	http.HandleFunc("/leaveGroup", leaveGroup)
	http.HandleFunc("/getUserInfo", getUserInfo)
	http.HandleFunc("/uploadImage", uploadImage)
	http.HandleFunc("/createGroup", createGroup)
	http.HandleFunc("/validateUser", validateUser)
	http.HandleFunc("/getUserGroups", getUserGroups)
	http.HandleFunc("/registerClient", registerClient)
	http.HandleFunc("/getUserFriends", getUserFriends)
	http.HandleFunc("/changePassword", changePassword)
	http.HandleFunc("/addGroupMembers", addGroupMembers)
	http.HandleFunc("/searchNewGroups", searchNewGroups)
	http.HandleFunc("/saveGroupUpdates", saveGroupUpdates)
	http.HandleFunc("/changePersonalInfo", changePersonalInfo)

	http.ListenAndServe(":9000", nil)
}

func CheckError(err error) {
	if err != nil {
		panic(err)
	}
}

// func init() {

// 	connStr := "postgres://postgres:password@localhost/retrievetest?sslmode=disable"
// 	db, err = sql.Open("postgres", connStr)

// 	if err != nil {
// 	panic(err)
// }

//always connected or when called?
