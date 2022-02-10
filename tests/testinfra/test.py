#   Copyright 2021
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may
#   not use this file except in compliance with the License. You may obtain
#   a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#   License for the specific language governing permissions and limitations
#   under the License.
#


def test_kind(host):
    assert host.docker("kind-control-plane").is_running


def test_web_docker_img(host):
    assert (
        len(
            host.run(
                "/usr/bin/docker images -q --filter reference='electrocucaracha/web'"
            ).stdout
        )
        > 0
    )


def test_helm_charts(host):
    cmd = host.run("/usr/local/bin/helm list --deployed --short")
    for chart in ["apiserver", "collector"]:
        assert "metric-" + chart in cmd.stdout


def test_deployment(host):
    assert host.run("/usr/local/bin/kubectl get deployments.apps cpustats").succeeded
