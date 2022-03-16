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

package api

import (
	"html/template"
	"log"
	"net/http"

	linuxproc "github.com/c9s/goprocinfo/linux"
)

// IndexHandler reads CPU statistics on Linux distros and displays them on a web page.
func IndexHandler(writer http.ResponseWriter, r *http.Request) {
	stat, err := linuxproc.ReadStat("/proc/stat")
	if err != nil {
		log.Printf("Server can't read CPU stats")
		http.Error(writer, "Server can't read CPU stats", http.StatusInternalServerError)
	}

	if stat != nil {
		tpl := template.Must(template.ParseFiles("web/template/index.html"))
		if err := tpl.Execute(writer, stat.CPUStatAll); err != nil {
			log.Printf("CPU stats can't be displayed")
			http.Error(writer, "CPU stats can't be displayed", http.StatusInternalServerError)
		}
	}
}
