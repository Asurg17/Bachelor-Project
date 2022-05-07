package main

import (
	"database/sql"
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

	username := req.URL.Query().Get("username")
	firstName := req.URL.Query().Get("firstName")
	lastName := req.URL.Query().Get("lastName")
	phoneNumber := req.URL.Query().Get("phoneNumber")
	password := req.URL.Query().Get("password")

	print(username, firstName, lastName, phoneNumber, password)

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer db.Close()

	insertSmt := `insert into "users" ("username", "password", "first_name", "last_name") values($1, $2, $3, $4)`
	_, e := db.Exec(insertSmt, username, password, firstName, lastName)
	if e != nil {
		w.Header().Set("Error", e.Error())
		w.WriteHeader(400)
		http.Error(w, e.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(200)
}

func checkUser(w http.ResponseWriter, req *http.Request) {

	if req.Method != "GET" {
		http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
		return
	}

	username := req.URL.Query().Get("username")
	givenPassword := req.URL.Query().Get("password")

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

	var actualPassword string
	getQuery := `select s.password from users s where s.username = $1`
	if err := db.QueryRow(getQuery, username).Scan(&actualPassword); err != nil {
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

	if givenPassword != actualPassword {
		w.Header().Set("Error", "Incorrect Password!")
		w.WriteHeader(400)
		http.Error(w, "Incorrect Password!", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(200)

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
