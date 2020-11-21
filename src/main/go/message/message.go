package main

import (
	"log"
	"message_object"
)

func main() {
	m := message_object.MessageObject{
		Message: "message value",
	}
	log.Printf("%v", m)
}
