package main

import (
	"github.com/kristiyankiryakov/distributed-services/internal/server"
	"log"
)

func main() {
	srv := server.NewHTTPServer(":8080")
	log.Fatal(srv.ListenAndServe())
}
