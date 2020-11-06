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
	"fmt"
	"html/template"
	"net/http"
	"os"

	linuxproc "github.com/c9s/goprocinfo/linux"
        "github.com/prometheus/client_golang/prometheus"
        "github.com/prometheus/client_golang/prometheus/promauto"
        "github.com/prometheus/client_golang/prometheus/promhttp"
)

var tpl = template.Must(template.ParseFiles("index.html"))
var (
        reqsProcessed = promauto.NewCounter(prometheus.CounterOpts{
                Name: "processed_requests_total",
                Help: "The total number of processed requests",
        })
)

func indexHandler(w http.ResponseWriter, r *http.Request) {
	stat, err := linuxproc.ReadStat("/proc/stat")
	if err != nil {
		panic("stat read fail")
	}

	tpl.Execute(w, stat.CPUStatAll)
	reqsProcessed.Inc()
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", indexHandler)
	mux.Handle("/metrics", promhttp.Handler())

	fmt.Println("Starting server at " + port)
	http.ListenAndServe(":"+port, mux)
}
