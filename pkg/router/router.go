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

package router

import (
	"net/http"

	"github.com/electrocucaracha/k8s-HorizontalPodAutoscaler-demo/pkg/api"
	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Router provides a custom Gorilla mux router.
type Router struct {
	*mux.Router
}

// CreateRouter initializes a custom router and their counters.
func CreateRouter() (router *Router) {
	reqsProcessed := promauto.NewCounter(prometheus.CounterOpts{
		Name: "processed_requests_total",
		Help: "CPU stats API number of processed requests",
	})

	router = &Router{
		mux.NewRouter().StrictSlash(true),
	}
	router.HandleFunc("/", api.WrapHandler(api.IndexHandler, reqsProcessed)).Methods(http.MethodGet)
	router.Handle("/metrics", promhttp.Handler())

	return router
}
