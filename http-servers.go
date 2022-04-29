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
	fmt.Fprintf(w, "hello\n")

	psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	db, err := sql.Open("postgres", psqlconn)
	CheckError(err)

	defer db.Close()

	insertSmt := `insert into "test_table" ("Id", "name") values(9, '{~}')`
	_, e := db.Exec(insertSmt)

	CheckError(e)
}

func main() {
	http.HandleFunc("/registerClient", registerClient)
	http.ListenAndServe(":8080", nil)
}

func CheckError(err error) {
	if err != nil {
		panic(err)
	}
}
