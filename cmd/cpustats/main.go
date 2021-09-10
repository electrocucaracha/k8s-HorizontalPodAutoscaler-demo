/*
Copyright 2020
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"log"
	"net/http"
	"os"

	"github.com/electrocucaracha/k8s-HorizontalPodAutoscaler-demo/pkg/router"
	"github.com/rs/cors"
)

var (
	version = "dev"
	commit  = "n/a"
	date    = "n/a"
)

func main() {
	var port string
	if port = os.Getenv("PORT"); port == "" {
		port = "3000"
	}

	router := router.CreateRouter()

	log.Println("Starting server at " + port)
	log.Printf("version: %s\tcommit:%s\tdate:%s\n", version, commit, date)

	if err := http.ListenAndServe(":"+port, cors.Default().Handler(router)); err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
