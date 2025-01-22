package main

import (
	"fmt"
	"net/http"
	"log"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("A simple web application running on 8080 pors")
	fmt.Fprintln(w, "Hello World!")
}

func main() {
	http.HandleFunc("/", handler)
	log.Println("Server starting on port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
