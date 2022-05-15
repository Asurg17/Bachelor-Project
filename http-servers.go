package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"

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
	w.Header().Set("Content-Type", "application/text")
	w.Write([]byte(userId))
}

func checkUser(w http.ResponseWriter, req *http.Request) {

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
	w.Header().Set("Content-Type", "application/text")
	w.Write([]byte(userId))
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

	updateQuery := `update users s set s.password = $1 where s.user_id = $2`

	_, e := db.Exec(updateQuery, newPasswordMdStr, userId)
	if e != nil {
		w.Header().Set("Error", "Can't update password!")
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

	http.HandleFunc("/registerClient", registerClient)
	http.HandleFunc("/checkUser", checkUser)
	http.HandleFunc("/getUserInfo", getUserInfo)
	http.HandleFunc("/changePassword", changePassword)
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
