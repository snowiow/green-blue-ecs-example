package main

import (
	"log"
	"net/http"
)

func fileHandler() http.Handler {
	return http.FileServer(http.Dir("static"))
}

func main() {

	http.Handle("/", fileHandler())

	log.Fatal(http.ListenAndServe(":80", nil))
}
