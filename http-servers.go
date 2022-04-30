package main

import (
	"fmt"
	"log"
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

	fmt.Println(req)
	fmt.Fprint(w, "Hellow World")

	// psqlconn := fmt.Sprintf("host=%s port=%d user=%s dbname=%s sslmode=disable", host, port, user, dbname)

	// db, err := sql.Open("postgres", psqlconn)
	// CheckError(err)

	// defer db.Close()

	// insertSmt := `insert into "test_table" ("Id", "name") values(9, '{~}')`
	// _, e := db.Exec(insertSmt)

	// CheckError(e)
}

func main() {
	// handle `/` route
	http.HandleFunc("/", func(res http.ResponseWriter, req *http.Request) {
		fmt.Fprint(res, "Hello World!")
	})

	log.Fatal(http.ListenAndServeTLS(":9000", "localhost.crt", "localhost.key", nil))
	http.HandleFunc("/registerClient", registerClient)
}

func CheckError(err error) {
	if err != nil {
		panic(err)
	}
}
