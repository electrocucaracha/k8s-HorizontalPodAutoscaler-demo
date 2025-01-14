# Kubernetes Horizontal Pod Autoscaler

<!-- markdown-link-check-disable-next-line -->

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

## Summary

This project was created to demonstrate what components are required
by an application to consume [Kubernetes Horizontal Pod Autoscaler][1]
feature.

The [k6.yml](tests/k6.yml) provides a traffic simulator which
generates virtual users, those users perform HTTP requests against the
web server. The _Prometheus_ instance collects custom metrics which
are aggreated by _Prometheus Adapter_ and consumed by _Horizontal Pod
Autoscaler_, this last component triggers actions to scale out/in
replicas in order to distribute the workload.

![Dashboard](img/diagram.png)

## Virtual Machines

The [Vagrant tool][2] can be used for provisioning an Ubuntu Focal
Virtual Machine. It's highly recommended to use the _setup.sh_ script
of the [bootstrap-vagrant project][3] for installing Vagrant
dependencies and plugins required for this project. That script
supports two Virtualization providers (Libvirt and VirtualBox) which
are determine by the **PROVIDER** environment variable.

    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to provision a Virtual
Machine using the following instructions:

    vagrant up

The provisioning process will take some time to install all
dependencies required by this project and perform a Kubernetes
deployment on it.

[1]: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
